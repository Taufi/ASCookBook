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
    
    var body: some View {
        List {
            ForEach(recipes) { recipe in
                VStack(alignment: .leading) {
                    Text(recipe.name)
                        .fontWeight(.bold)
                    Text(recipe.place ?? "Unknown place")
                    Text(recipe.season?.title ?? "Unknown season")
                    Text(recipe.category?.title ?? "Unknown category")
                    Text(String(recipe.photoId ?? 0))
                }
            }
        }
        .task {
            if recipes.isEmpty {
                if let dbURL = getWritableDatabaseURL() {
                    importLegacyDatabase(dbPath: dbURL.path, context: context)
                }
            }
        }
        
    }
}

#Preview {
    ContentView()
}
