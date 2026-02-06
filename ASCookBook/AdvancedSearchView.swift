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
    
    @Query(sort: [SortDescriptor(\Category.title)]) private var categories: [Category]
    @Query(sort: [SortDescriptor(\Season.title)]) private var seasons: [Season]
    
    // Ingredient search
    @State private var ingredient1: String = ""
    @State private var ingredient2: String = ""
    @State private var ingredient3: String = ""
    
    // Filter criteria
    @State private var selectedCategory: Category?
    @State private var selectedSeason: Season?
    @State private var selectedKinds: Kind = Kind(rawValue: 0)
    @State private var selectedSpecials: Special = Special(rawValue: 0)
    
    private var allIngredients: [String] {
        [ingredient1, ingredient2, ingredient3].filter { !$0.isEmpty }
    }
    
    private var hasActiveFilters: Bool {
        !allIngredients.isEmpty ||
        selectedCategory != nil ||
        selectedSeason != nil ||
        !selectedKinds.isEmpty ||
        !selectedSpecials.isEmpty
    }
    
    private var filteredRecipes: [Recipe] {
        return recipes.filter { recipe in
            // Filter by ingredients
            let matchesIngredients: Bool = {
                if allIngredients.isEmpty {
                    return true
                }
                let ingredients = recipe.ingredients.lowercased()
                return allIngredients.allSatisfy { ingredient in
                    ingredients.localizedCaseInsensitiveContains(ingredient)
                }
            }()
            
            // Filter by category
            let matchesCategory: Bool = {
                guard let selectedCategory = selectedCategory else { return true }
                return recipe.category.title == selectedCategory.title
            }()
            
            // Filter by season
            let matchesSeason: Bool = {
                guard let selectedSeason = selectedSeason else { return true }
                return recipe.season.title == selectedSeason.title
            }()
            
            // Filter by kinds
            let matchesKinds: Bool = {
                if selectedKinds.isEmpty {
                    return true
                }
                return selectedKinds.isSubset(of: recipe.kinds) // if all selected kinds must match
            }()
            
            // Filter by specials
            let matchesSpecials: Bool = {
                if selectedSpecials.isEmpty {
                    return true
                }
                return selectedSpecials.isSubset(of: recipe.specials) // if all selected specials must match
            }()
            
            return matchesIngredients && matchesCategory && matchesSeason && matchesKinds && matchesSpecials
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search form
                Form {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Geben Sie bis zu 3 Zutaten ein, um Rezepte zu finden, die alle diese Zutaten enthalten.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            TextField("Zutat 1", text: $ingredient1)
                                .textFieldStyle(.roundedBorder)
                            
                            TextField("Zutat 2", text: $ingredient2)
                                .textFieldStyle(.roundedBorder)
                            
                            TextField("Zutat 3", text: $ingredient3)
                                .textFieldStyle(.roundedBorder)
                        }
                    } header: {
                        Text("Zutaten")
                            .fontWeight(.bold)
                    }
                    
                    Section {
                        Picker("Kategorie", selection: $selectedCategory) {
                            Text("Alle").tag(nil as Category?)
                            ForEach(categories, id: \.title) { category in
                                Text(category.title).tag(category as Category?)
                            }
                        }
                    } header: {
                        Text("Kategorie")
                            .fontWeight(.bold)
                    }
                    
                    Section {
                        Picker("Jahreszeit", selection: $selectedSeason) {
                            Text("Alle").tag(nil as Season?)
                            ForEach(seasons, id: \.title) { season in
                                Text(season.title).tag(season as Season?)
                            }
                        }
                    } header: {
                        Text("Jahreszeit")
                            .fontWeight(.bold)
                    }
                    
                    Section {
                        ForEach(Kind.allCases, id: \.rawValue) { kind in
                            Toggle(kind.displayName, isOn: binding(for: kind))
                        }
                    } header: {
                        Text("Art des Rezeptes")
                            .fontWeight(.bold)
                    }
                    
                    Section {
                        ForEach(Special.allCases, id: \.rawValue) { special in
                            Toggle(special.displayName, isOn: binding(for: special))
                        }
                    } header: {
                        Text("Verwendung als...")
                            .fontWeight(.bold)
                    }
                    
                    Section {
                        HStack {
                            Button("Alle Filter löschen") {
                                clearSearch()
                            }
                            .foregroundColor(.blue)
                            
                            Spacer()
                            
                            Text("\(filteredRecipes.count) Rezepte gefunden")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .formStyle(.grouped)
                
                Divider()
                
                // Results
                if filteredRecipes.isEmpty && hasActiveFilters {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundStyle(.secondary)
                        
                        Text("Keine Rezepte gefunden")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text("Versuchen Sie andere Suchkriterien oder weniger Filter.")
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
    
    private func binding(for kind: Kind) -> Binding<Bool> {
        Binding(
            get: { selectedKinds.contains(kind) },
            set: { isOn in
                if isOn {
                    selectedKinds.insert(kind)
                } else {
                    selectedKinds.remove(kind)
                }
            }
        )
    }
    
    private func binding(for special: Special) -> Binding<Bool> {
        Binding(
            get: { selectedSpecials.contains(special) },
            set: { isOn in
                if isOn {
                    selectedSpecials.insert(special)
                } else {
                    selectedSpecials.remove(special)
                }
            }
        )
    }
    
    private func clearSearch() {
        ingredient1 = ""
        ingredient2 = ""
        ingredient3 = ""
        selectedCategory = nil
        selectedSeason = nil
        selectedKinds = Kind(rawValue: 0)
        selectedSpecials = Special(rawValue: 0)
    }
}

#Preview {
    AdvancedSearchView(recipes: [])
}
