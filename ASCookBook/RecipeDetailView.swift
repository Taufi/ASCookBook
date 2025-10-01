//
//  RecipeDetailView.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 28.09.25.
//
import SwiftUI

struct RecipeDetailView: View {
    @Bindable var recipe: Recipe
    
    var body : some View {
        ScrollView {
            Text(recipe.name)
                .font(.title)
                .padding()
            image
            ingredients
        }
    }

    private var image : some View {
        VStack {
            let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let imageURL = appSupportURL.appendingPathComponent("image" + String(recipe.photoId ?? 0) + ".jpg")
            if FileManager.default.fileExists(atPath: imageURL.path) {
                // show image from file system
                if let uiImage = UIImage(contentsOfFile: imageURL.path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .padding()
                } else {
                    Text("Bild konnte nicht geladen werden")
                        .padding()
                }
            }
        }
    }
    
    private var ingredients: some View {
        Section {
            TextEditor(text: $recipe.ingredients)
                .multilineTextAlignment(.leading)
                .frame(minHeight: 100)
                .padding()
        } header: {
            Text("Zutaten und Zubereitung")
                .fontWeight(.bold)
        }
    }
    
}

#Preview {
    RecipeDetailView(recipe: Recipe(name: "Testrezept", place: "Test", ingredients: "100 g Zucker,\n100 g Eiweiß", portions: "Test", season: Season(title: "Test"), category: Category(title: "Test"), photoId: 1))
}


