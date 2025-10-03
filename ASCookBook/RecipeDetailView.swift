//
//  RecipeDetailView.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 28.09.25.
//
import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var recipe: Recipe
    @State private var isEditing = false
    
    var body : some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if isEditing {
                    TextField("Name des Rezeptes", text: $recipe.name)
                        .textFieldStyle(.roundedBorder)
                    image
                    editKind
                    editIngredients
                } else {
                    Text(recipe.name)
                        .font(.title)
                        .padding()
                    image
                    if !recipe.kinds.isEmpty {
                        Section {
                            Text(recipe.kinds.title)
                        } header: {
                            Text("Art des Rezeptes")
                                .fontWeight(.bold)
                        }
                    }
                    showIngredients
                }
            }
            .padding()
        }
        .navigationTitle(recipe.name)
        .toolbar {
            if isEditing {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isEditing = false
                        //KD TODO Rollback
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        do {
                            try context.save()
                        } catch {
                            print("-------> ERROR SAVING CONTEXT")
                        }
                        isEditing = false
                    }
                }
                
            } else {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        isEditing = true
                    }
                }
            }
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
    
    private var showIngredients: some View {
        Section {
            Text(recipe.ingredients)
        } header: {
            Text("Zutaten und Zubereitung")
                .fontWeight(.bold)
        }
    }
    
    private var editKind: some View {
        Section {
            ForEach(Kind.allCases, id: \.rawValue) { kind in
                Toggle(kind.displayName, isOn: binding(for: kind))
            }
        }  header: {
            Text("Art des Rezeptes")
                .fontWeight(.bold)
        }
    }
    
    private var editIngredients: some View {
        Section {
            TextEditor(text: $recipe.ingredients)
                .frame(height: 300)
                .border(.gray)
        } header: {
            Text("Zutaten und Zubereitung")
                .fontWeight(.bold)
        }
    }
    
    // Helper: bind a toggle to OptionSet membership
    private func binding(for kind: Kind) -> Binding<Bool> {
        Binding(
            get: { recipe.kinds.contains(kind) },
            set: { isOn in
                if isOn {
                    recipe.kinds.insert(kind)
                } else {
                    recipe.kinds.remove(kind)
                }
            }
        )
    }
}

#Preview {
    RecipeDetailView(recipe: Recipe(name: "Testrezept", place: "Test", ingredients: "100 g Zucker,\n100 g Eiweiß", portions: "Test", season: Season(title: "Test"), category: Category(title: "Test"), photoId: 1, kinds: [.fish, .meat]))
}

