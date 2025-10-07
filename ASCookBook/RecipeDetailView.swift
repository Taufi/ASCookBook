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
    @Query private var categories: [Category]
    @Query private var seasons: [Season]
    
    var body : some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if isEditing {
                    TextField("Name des Rezeptes", text: $recipe.name)
                        .textFieldStyle(.roundedBorder)
                    showImage
                    editCategory
                    editSeason
                    editKinds
                    editSpecials
                    editIngredients
//                    editPlace
//                    editPortions
                } else {
                    Text(recipe.name)
                        .font(.title)
                        .padding()
                    showImage
                    showCategory
                    showSeason
                    showKinds
                    showSpecials
                    showIngredients
                    showPlace
                    showPortions
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

    private var showImage : some View {
        VStack {
            let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let imageURL = appSupportURL.appendingPathComponent("image" + String(recipe.photoId ?? 0) + ".jpg")
            if FileManager.default.fileExists(atPath: imageURL.path) {
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
    
    private var showCategory: some View {
        Section {
            Text("\(recipe.category?.title ?? "Keine Kategorie")")
        } header: {
            Text("Kategorie")
                .fontWeight(.bold)
        }
    }
    
    private var showSeason: some View {
        Section {
            Text("\(recipe.season?.title ?? "Keine Jahreszeit")")
        } header: {
            Text("Jahreszeit")
                .fontWeight(.bold)
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
    
    private var showPortions: some View {
        Group {
            let trimmed = recipe.portions.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                Section {
                    Text(trimmed)
                } header: {
                    Text("Portionen")
                        .fontWeight(.bold)
                }
            }
        }
    }
    
    private var showPlace: some View {
        Group {
            let trimmed = recipe.place?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !trimmed.isEmpty {
                Section {
                    // Try to create a URL; if scheme is missing (e.g. starts with www.), try https://
                    if let url = URL(string: trimmed), url.scheme != nil {
                        Link(trimmed, destination: url)
                    } else if let url = URL(string: "https://" + trimmed), URL(string: trimmed)?.scheme == nil, url.host != nil {
                        Link(trimmed, destination: url)
                    } else {
                        Text(trimmed)
                    }
                } header: {
                    Text("Quelle")
                        .fontWeight(.bold)
                }
            }
        }
    }
    
    private var showKinds: some View {
        Group {
            if !recipe.kinds.isEmpty {
                Section {
                    Text(recipe.kinds.title)
                } header: {
                    Text("Art des Rezeptes")
                        .fontWeight(.bold)
                }
            }
        }
    }
    
    private var showSpecials: some View {
        Group {
            if !recipe.specials.isEmpty {
                Section {
                    Text(recipe.specials.title)
                } header: {
                    Text("Verwendung als...")
                        .fontWeight(.bold)
                }
            }
        }
    }
    
    private var editCategory: some View {
        Section {
            Picker("Kategorie", selection: $recipe.category) {
                ForEach(categories, id: \.title) { category in
                    Text(category.title)
                        .tag(category)
                }
            }
        } header: {
            Text("Kategorie")
                .fontWeight(.bold)
        }
    }
    
    private var editSeason: some View {
        Section {
            Picker("Jahreszeit", selection: $recipe.season) {
                ForEach(seasons, id: \.title) { season in
                    Text(season.title)
                        .tag(season)
                }
            }
        } header: {
            Text("Jahreszeit")
                .fontWeight(.bold)
        }
    }
    
    private var editKinds: some View {
        Section {
            ForEach(Kind.allCases, id: \.rawValue) { kind in
                Toggle(kind.displayName, isOn: $recipe.binding(for: kind))
            }
        }  header: {
            Text("Art des Rezeptes")
                .fontWeight(.bold)
        }
    }
    
    private var editSpecials: some View {
        Section {
            ForEach(Special.allCases, id: \.rawValue) { special in
                // Different approach than with kind to test both options: recipe and binding $recipe
                Toggle(special.displayName, isOn: recipe.binding(for: special))
            }
        }  header: {
            Text("Verwendung als...")
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
}

#Preview {
    RecipeDetailView(recipe: Recipe(name: "Testrezept", place: "Test", ingredients: "100 g Zucker,\n100 g Eiweiß", portions: "Test", season: Season(title: "Test"), category: Category(title: "Test"), photoId: 1, kinds: [.fish, .meat], specials: [.soup, .snack]))
}
