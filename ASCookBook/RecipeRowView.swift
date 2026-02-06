//
//  RecipeRowView.swift
//  ASCookBook
//

import SwiftUI
import SwiftData

struct RecipeRowView: View {
    let recipe: Recipe

    var body: some View {
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
