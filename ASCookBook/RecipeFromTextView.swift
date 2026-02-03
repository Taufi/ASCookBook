//
//  RecipeFromTextView.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 03.02.25.
//

import SwiftUI

struct RecipeFromTextView: View {
    @Binding var result: RecipeResponse?
    @Environment(\.dismiss) private var dismiss
    
    @State private var recipeText: String = ""
    @State private var isProcessing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Fügen Sie den Rezepttext ein (z.B. aus einer Webseite oder Notizen).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                TextEditor(text: $recipeText)
                    .font(.body)
                    .frame(minHeight: 200)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                
                if isProcessing {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Rezept wird verarbeitet...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                
                Spacer(minLength: 0)
            }
            .padding()
            .navigationTitle("Rezept aus Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                    .disabled(isProcessing)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Rezept erstellen") {
                        Task { await createRecipe() }
                    }
                    .disabled(recipeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
                }
            }
            .alert("Fehler beim Verarbeiten", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func createRecipe() async {
        let text = recipeText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        await MainActor.run { isProcessing = true }
        
        let service = TextRecognitionService()
        
        do {
            let response = try await service.recipeFromText(text)
            await MainActor.run {
                result = response
                isProcessing = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                isProcessing = false
                if let nsError = error as NSError? {
                    switch nsError.domain {
                    case "TextRecognitionService":
                        errorMessage = "Fehler bei der Texterkennung: \(nsError.localizedDescription)"
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
}

#Preview {
    RecipeFromTextView(result: .constant(nil))
}
