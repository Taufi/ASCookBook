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
    
    var filteredRecipes: [Recipe] {
        if searchText.isEmpty {
            return recipes
        } else {
            return recipes.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.ingredients.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredRecipes) { recipe in
                    NavigationLink(value: recipe) {
                        HStack(alignment: .top, spacing: 12) {
                            if let image = imageForRecipe(photoId: recipe.photoId) {
                                image
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
            .task {
                if recipes.isEmpty {
                    if let dbURL = getWritableDatabaseURL() {
                        importLegacyDatabase(dbPath: dbURL.path, context: context)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Suche Rezepte")
            .navigationTitle("Rezepte")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: addNewRecipe) {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe, startInEditMode: recipe == addedRecipe)
            }
            .navigationDestination(item: $addedRecipe) { recipe in
                RecipeDetailView(recipe: recipe, startInEditMode: true)
            }
        }
    }
    
    func imageForRecipe(photoId: Int?) -> Image? {
        guard let photoId = photoId else { return nil }
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        guard let appSupportURL = urls.first else { return nil }
        let imageURL = appSupportURL.appendingPathComponent("image\(photoId).jpg")
        if let uiImage = UIImage(contentsOfFile: imageURL.path) {
            return Image(uiImage: uiImage)
        } else {
            return nil
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
            photoId: nil,
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
            context.delete(recipes[index])
        }
    }
    
}

#Preview {
    ContentView()
}

