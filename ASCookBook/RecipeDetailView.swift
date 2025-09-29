//
//  RecipeDetailView.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 28.09.25.
//
import SwiftUI

struct RecipeDetailView: View {
    var recipe: Recipe
    
    var body : some View {
        VStack {
            Text(recipe.name)
                .font(.largeTitle)
                .padding()
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
                } else {
                    Text("Kein Bild verfügbar")
                        .padding()
                }
        }
    }
}

#Preview {
    RecipeDetailView(recipe: Recipe(name: "Test", place: "Test", ingredients: "Test", portions: "Test", season: Season(title: "Test"), category: Category(title: "Test"), photoId: 1))
}


