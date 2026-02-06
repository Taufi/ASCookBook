//
//  RecipeFromTextView.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 03.02.25.
//

import SwiftUI

struct RecipeFromTextView: View {
    @Binding var pendingRecipeText: String?
    @Environment(\.dismiss) private var dismiss
    
    @State private var recipeText: String = ""
    
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
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Rezept erstellen") {
                        let trimmed = recipeText.trimmingCharacters(in: .whitespacesAndNewlines)
                        pendingRecipeText = trimmed
                        dismiss()
                    }
                    .disabled(recipeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    RecipeFromTextView(pendingRecipeText: .constant(nil))
}
