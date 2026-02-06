//
//  RecipeImportViewModel.swift
//  ASCookBook
//

import SwiftData
import SwiftUI

@MainActor
@Observable
final class RecipeImportViewModel {
    var isProcessingRecipe = false
    var processingProgress: Double = 0.0
    var processingMessage = ""
    var showingError = false
    var errorMessage = ""

    private let service = TextRecognitionService()

    /// Call when user picks an image; creates a recipe and reports it via onRecipeCreated.
    func recipeFromPhoto(
        imageData: Data,
        context: ModelContext,
        onRecipeCreated: @escaping (Recipe) -> Void
    ) async {
        isProcessingRecipe = true
        processingProgress = 0.0
        processingMessage = "Bild wird analysiert..."

        do {
            processingProgress = 0.3
            processingMessage = "Text wird erkannt..."

            let recipeResponse = try await service.extractRecipe(from: imageData)

            processingProgress = 0.7
            processingMessage = "Rezept wird verarbeitet..."

            let ingredientsBlock = recipeResponse.ingredients.joined(separator: "\n")
            let instructions = [ingredientsBlock, recipeResponse.instructions]
                .compactMap { $0 }
                .joined(separator: "\n\n")

            processingProgress = 0.9
            processingMessage = "Rezept wird gespeichert..."

            let newRecipe = Recipe(
                name: recipeResponse.title,
                place: "",
                ingredients: instructions,
                portions: recipeResponse.servings ?? "",
                season: Season.fetchOrCreate(title: "immer", in: context),
                category: Category.fetchOrCreate(title: "Hauptspeisen", in: context),
                photo: imageData,
                kinds: Kind(rawValue: 1),
                specials: Special(rawValue: 0),
            )
            context.insert(newRecipe)
            try? context.save()
            onRecipeCreated(newRecipe)

            processingProgress = 1.0
            processingMessage = "Fertig!"

            try? await Task.sleep(nanoseconds: 500_000_000)
            resetProgress()
        } catch {
            print("Error extracting recipe from photo: \(error)")
            showError(error)
            resetProgress()
        }
    }

    /// Call when user submits text; creates a recipe and reports it via onRecipeCreated.
    func recipeFromText(
        _ text: String,
        context: ModelContext,
        onRecipeCreated: @escaping (Recipe) -> Void
    ) async {
        isProcessingRecipe = true
        processingProgress = 0.5
        processingMessage = "Rezept wird verarbeitet..."

        do {
            let recipeResponse = try await service.recipeFromText(text)

            processingProgress = 0.75
            processingMessage = "Rezept wird gespeichert..."

            let ingredientsBlock = recipeResponse.ingredients.joined(separator: "\n")
            let instructions = [ingredientsBlock, recipeResponse.instructions]
                .compactMap { $0 }
                .joined(separator: "\n\n")

            let newRecipe = Recipe(
                name: recipeResponse.title,
                place: "",
                ingredients: instructions,
                portions: recipeResponse.servings ?? "",
                season: Season.fetchOrCreate(title: "immer", in: context),
                category: Category.fetchOrCreate(title: "Hauptspeisen", in: context),
                photo: nil,
                kinds: Kind(rawValue: 1),
                specials: Special(rawValue: 0),
            )
            context.insert(newRecipe)
            try? context.save()
            onRecipeCreated(newRecipe)

            processingProgress = 1.0
            processingMessage = "Fertig!"

            try? await Task.sleep(nanoseconds: 500_000_000)
            resetProgress()
        } catch {
            showError(error)
            resetProgress()
        }
    }

    private func resetProgress() {
        isProcessingRecipe = false
        processingProgress = 0.0
        processingMessage = ""
    }

    private func showError(_ error: Error) {
        if let nsError = error as NSError? {
            switch nsError.domain {
            case "TextRecognitionService":
                switch nsError.code {
                case 1:
                    errorMessage = "Das Bild konnte nicht verarbeitet werden. Bitte versuchen Sie es mit einem anderen Foto."
                case 2:
                    errorMessage = "Das Bildformat wird nicht unterstützt. Bitte verwenden Sie ein anderes Foto."
                case 3:
                    errorMessage = "Kein Text im Bild gefunden. Bitte fotografieren Sie ein Rezept mit lesbarem Text."
                default:
                    errorMessage = "Fehler bei der Texterkennung: \(nsError.localizedDescription)"
                }
            case "OpenAIService":
                errorMessage = "Fehler beim Verarbeiten des Rezepts. Code: \(nsError.code). Bitte überprüfen Sie Ihre Internetverbindung und versuchen Sie es erneut."
            default:
                errorMessage = "Ein unbekannter Fehler ist aufgetreten: \(nsError.localizedDescription)"
            }
        } else {
            errorMessage = "Ein Fehler ist aufgetreten: \(error.localizedDescription)"
        }
        showingError = true
    }
}
