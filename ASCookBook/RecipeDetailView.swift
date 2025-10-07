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
                    TextField("Quelle des Rezepts", text: $recipe.place)
                        .textFieldStyle(.roundedBorder)
                    TextField("Portionen", text: $recipe.portions)
                        .textFieldStyle(.roundedBorder)
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
                    Button("Abbrechen") {
                        isEditing = false
                        //KD TODO Rollback
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
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
        showSection(content: recipe.category.title, header: "Kategorie")
    }
    
    private var showSeason: some View {
        showSection(content: recipe.season.title, header: "Jahreszeit")
    }
    
    private var showIngredients: some View {
        showSection(
            content: recipe.ingredients,
            header: "Zutaten und Zubereitung",
            condition: !recipe.ingredients.isEmpty
        )
    }
    
    private var showPortions: some View {
        showSection(
            content: recipe.portions,
            header: "Portionen",
            condition: !recipe.portions.isEmpty
        )
    }
    
    private var showPlace: some View {
        Group {
            let place = recipe.place
            if !place.isEmpty {
                Section {
                    // Try to create a URL; if scheme is missing (e.g. starts with www.), try https://
                    if let url = URL(string: place), url.scheme != nil {
                        Link(place, destination: url)
                    } else if let url = URL(string: "https://" + place), URL(string: place)?.scheme == nil, url.host != nil {
                        Link(place, destination: url)
                    } else {
                        Text(place)
                    }
                } header: {
                    Text("Quelle")
                        .fontWeight(.bold)
                }
            }
        }
    }
    
    private var showKinds: some View {
        showSection(
            content: recipe.kinds.title,
            header: "Art des Rezeptes",
            condition: !recipe.kinds.isEmpty
        )
    }
    
    private var showSpecials: some View {
        showSection(
            content: recipe.specials.title,
            header: "Verwendung als...",
            condition: !recipe.specials.isEmpty
        )
    }
    
    private var editCategory: some View {
        editPickerSection(
            selection: $recipe.category,
            items: categories,
            header: "Kategorie"
        )
    }
    
    private var editSeason: some View {
        editPickerSection(
            selection: $recipe.season,
            items: seasons,
            header: "Jahreszeit"
        )
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
    
    // MARK: - Generic Helper Methods
    
    /// Generic method to display a section with optional conditional rendering
    private func showSection(content: String, header: String, condition: Bool = true) -> some View {
        Group {
            if condition {
                Section {
                    Text(content)
                } header: {
                    Text(header)
                        .fontWeight(.bold)
                }
            }
        }
    }
    
    /// Generic method to create a picker-based edit section
    private func editPickerSection<T: TitledModel>(
        selection: Binding<T>,
        items: [T],
        header: String
    ) -> some View {
        Section {
            Picker(header, selection: selection) {
                ForEach(items, id: \.title) { item in
                    Text(item.title)
                        .tag(item)
                }
            }
        } header: {
            Text(header)
                .fontWeight(.bold)
        }
    }
}

#Preview {
    RecipeDetailView(recipe: Recipe(name: "Testrezept", place: "Test", ingredients: "100 g Zucker,\n100 g Eiweiß", portions: "Test", season: Season(title: "Test"), category: Category(title: "Test"), photoId: 1, kinds: [.fish, .meat], specials: [.soup, .snack]))
}
