//
//  ContentView.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 24.09.25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Recipe.name)]) private var recipes: [Recipe]
    @State private var searchText: String = ""
    @State private var addedRecipe: Recipe?
    @State private var showingAdvancedSearch = false
    
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var recipeImageData: Data?
    
    // Progress tracking for recipe processing
    @State private var isProcessingRecipe = false
    @State private var processingProgress: Double = 0.0
    @State private var processingMessage = ""
    
    // Error handling
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var filteredRecipes: [Recipe] {
        if searchText.isEmpty {
            return recipes
        } else {
            return recipes.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.ingredients.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if isProcessingRecipe {
                    VStack(spacing: 16) {
                        ProgressView(value: processingProgress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle())
                            .frame(maxWidth: 200)
                        
                        Text(processingMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                List {
                    ForEach(filteredRecipes) { recipe in
                        NavigationLink(value: recipe) {
                            HStack(alignment: .top, spacing: 12) {
                                if let photoData = recipe.photo, let uiImage = UIImage(data: photoData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else  {
                                    Image("Plate")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                VStack(alignment: .leading) {
                                    Text(recipe.name).bold()
                                    Text(recipe.category.title)
                                        .font(.subheadline).foregroundStyle(.secondary)
                                    Text(recipe.kinds.title)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteRecipes)
                }
            }
            .task {
                if recipes.isEmpty {
                    if let dbURL = Bundle.main.url(forResource: "CookBook", withExtension: "sqlite") {
                        importLegacyDatabase(dbPath: dbURL.path, context: context)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Suche Rezepte")
            .navigationTitle("Rezepte")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: addNewRecipe) {
                            Label("Neues Rezept", systemImage: "plus")
                        }
                        Button(action: { showingAdvancedSearch = true }) {
                            Label("Erweiterte Suche", systemImage: "magnifyingglass")
                        }
                        Button(action: { showingCamera = true }) {
                            Label("Rezept fotografieren", systemImage: "camera.on.rectangle")
                        }
                        Button(action: { showingPhotoLibrary = true }) {
                            Label("Rezeptfoto aus Galerie", systemImage: "photo.on.rectangle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe, startInEditMode: false)
            }
            .navigationDestination(item: $addedRecipe) { recipe in
                RecipeDetailView(recipe: recipe, startInEditMode: true)
            }
            .sheet(isPresented: $showingAdvancedSearch) {
                AdvancedSearchView(recipes: recipes)
            }
            .sheet(isPresented: $showingCamera) {
                CameraPicker(selectedImageData: $recipeImageData)
            }
            .sheet(isPresented: $showingPhotoLibrary) {
                PhotoLibraryPicker(selectedImageData: $recipeImageData)
            }
            .onChange(of: recipeImageData) {
                Task { await recipeFromPhoto() }
            }
            .alert("Fehler beim Verarbeiten", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func recipeFromPhoto() async {
        guard let imageData = recipeImageData else { return }
        
        // Start processing
        await MainActor.run {
            isProcessingRecipe = true
            processingProgress = 0.0
            processingMessage = "Bild wird analysiert..."
        }
        
        let service = TextRecognitionService()
        
        do {
            // Update progress for text recognition
            await MainActor.run {
                processingProgress = 0.3
                processingMessage = "Text wird erkannt..."
            }
            
            let recipeResponse = try await service.extractRecipe(from: imageData)
            
            // Update progress for recipe processing
            await MainActor.run {
                processingProgress = 0.7
                processingMessage = "Rezept wird verarbeitet..."
            }

            let ingredientsBlock = recipeResponse.ingredients.joined(separator: "\n")
            let instructions = [ingredientsBlock, recipeResponse.instructions]
                .compactMap { $0 }
                .joined(separator: "\n\n")
            
            // Update progress for saving
            await MainActor.run {
                processingProgress = 0.9
                processingMessage = "Rezept wird gespeichert..."
            }
            
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
            addedRecipe = newRecipe
            try? context.save()
            
            // Complete processing
            await MainActor.run {
                processingProgress = 1.0
                processingMessage = "Fertig!"
            }
            
            // Hide progress after a short delay
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            await MainActor.run {
                isProcessingRecipe = false
                processingProgress = 0.0
                processingMessage = ""
            }
            
        } catch {
            print("Error extracting recipe from photo: \(error)")
            
            // Reset progress state on error
            await MainActor.run {
                isProcessingRecipe = false
                processingProgress = 0.0
                processingMessage = ""
                
                // Show user-friendly error message
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
    }
    
    private func addNewRecipe() {
        let newRecipe = Recipe(
            name: "Neues Rezept",
            place: "",
            ingredients: "",
            portions: "",
            season: Season.fetchOrCreate(title: "immer", in: context),
            category: Category.fetchOrCreate(title: "Hauptspeisen", in: context),
            photo: nil,
            kinds: Kind(rawValue: 1),
            specials: Special(rawValue: 0),
        )
        context.insert(newRecipe)
        addedRecipe = newRecipe
        try? context.save()
    }
    
    //KD TODO Error: deletes wrong recipes when in search mode
    private func deleteRecipes(at offsets: IndexSet) {
        for index in offsets {
            context.delete(filteredRecipes[index])
        }
    }
}

#Preview {
    ContentView()
}

