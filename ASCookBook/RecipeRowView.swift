//
//  RecipeRowView.swift
//  ASCookBook
//

import SwiftUI
import SwiftData
import UIKit

struct RecipeRowView: View {
    let recipe: Recipe
    @State private var thumbnail: UIImage?

    var body: some View {
        NavigationLink(value: RecipeRoute(recipe: recipe)) {
            HStack(alignment: .top, spacing: 12) {
                Group {
                    if let thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Image("Plate")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading) {
                    Text(recipe.name).bold()
                    Text(recipe.category.title)
                        .font(.subheadline).foregroundStyle(.secondary)
                    Text(recipe.kinds.title)
                }
            }
        }
        .task(id: recipe.persistentModelID) {
            thumbnail = await RecipeThumbnailCache.thumbnail(for: recipe)
        }
    }
}

#Preview {
    List {
        RecipeRowView(recipe: Recipe(
            name: "Test",
            place: "",
            ingredients: "",
            portions: "",
            season: Season(title: "immer"),
            category: Category(title: "Hauptspeisen"),
            photo: nil,
            kinds: Kind(rawValue: 1),
            specials: Special(rawValue: 0)
        ))
    }
}
