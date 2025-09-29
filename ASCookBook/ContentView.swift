//
//  ContentView.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 24.09.25.
//

import SwiftUI
import SwiftData
import SQLite3

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query var recipes: [Recipe]
    
    // add navigation destination
    var body: some View {
        NavigationStack {
            List {
                ForEach(recipes) { recipe in
                    NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                        VStack(alignment: .leading) {
                            Text(recipe.name)
                                .fontWeight(.bold)
                            Text(recipe.place ?? "Unknown place")
                            Text(recipe.season?.title ?? "Unknown season")
                            Text(recipe.category?.title ?? "Unknown category")
                            Text(String(recipe.photoId ?? 0))
                            if !recipe.kinds.isEmpty {
                                Text(String(recipe.kinds[0].title))
                            }
                            if !recipe.specials.isEmpty {
                                Text(String(recipe.specials[0].title))
                            }
                        }
                    }
                }
                .navigationTitle("Rezepte")
            }
        }
    }
}

#Preview {
    ContentView()
}
