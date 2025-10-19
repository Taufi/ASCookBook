//
//  AdvancedSearchView.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 28.09.25.
//

import SwiftUI
import SwiftData

struct AdvancedSearchView: View {
    @Environment(\.dismiss) private var dismiss
    let recipes: [Recipe]
    
    @State private var ingredient1: String = ""
    @State private var ingredient2: String = ""
    @State private var ingredient3: String = ""
    
    private var allIngredients: [String] {
        [ingredient1, ingredient2, ingredient3].filter { !$0.isEmpty }
    }
    
    private var filteredRecipes: [Recipe] {
        if allIngredients.isEmpty {
            return recipes
        }
        
        return recipes.filter { recipe in
            let ingredients = recipe.ingredients.lowercased()
            return allIngredients.allSatisfy { ingredient in
                ingredients.localizedCaseInsensitiveContains(ingredient)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search form
                VStack(alignment: .leading, spacing: 16) {
                    Text("Erweiterte Suche")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    Text("Geben Sie bis zu 3 Zutaten ein, um Rezepte zu finden, die alle diese Zutaten enthalten.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        TextField("Zutat 1", text: $ingredient1)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Zutat 2", text: $ingredient2)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Zutat 3", text: $ingredient3)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        Button("Löschen") {
                            clearSearch()
                        }
                        .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Text("\(filteredRecipes.count) Rezepte gefunden")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Color(.systemGroupedBackground))
                
                Divider()
                
                // Results
                if filteredRecipes.isEmpty && !allIngredients.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundStyle(.secondary)
                        
                        Text("Keine Rezepte gefunden")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text("Versuchen Sie andere Zutaten oder weniger Zutaten.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                } else {
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
                                    } else {
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
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Erweiterte Suche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
        }
    }
    
    private func clearSearch() {
        ingredient1 = ""
        ingredient2 = ""
        ingredient3 = ""
    }
}

#Preview {
    AdvancedSearchView(recipes: [])
}
