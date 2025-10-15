//
//  RecipeDetailView.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 28.09.25.
//
import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var recipe: Recipe
    @State var isEditing: Bool
    private let isNew: Bool
    @Query private var categories: [Category]
    @Query private var seasons: [Season]
    
    // Store original values for rollback
    @State private var originalName: String = ""
    @State private var originalPlace: String = ""
    @State private var originalIngredients: String = ""
    @State private var originalPortions: String = ""
    @State private var originalSeason: Season?
    @State private var originalCategory: Category?
    @State private var originalKinds: Kind = Kind(rawValue: 0)
    @State private var originalSpecials: Special = Special(rawValue: 0)
    
    
    init(recipe: Recipe, startInEditMode: Bool = false) {
        self.recipe = recipe
        self.isEditing = startInEditMode
        self.isNew = startInEditMode
    }
    
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
//                    Text(recipe.name)
//                        .font(.largeTitle)
//                        .fontWeight(.bold)
//                        .padding()
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
//        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isEditing {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        handleCancel()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        handleSave()
                    }
                }
                
            } else {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        saveOriginalState()
                        isEditing = true
                    }
                }
            }
        }
    }

    private var showImage : some View {
        VStack {
            if let photoData = recipe.photo, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .padding()
            } else if recipe.photo != nil {
                Text("Bild konnte nicht geladen werden")
                    .padding()
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
        editToggleSection(
            allCases: Kind.allCases,
            binding: { $recipe.binding(for: $0) },
            displayName: { $0.displayName },
            header: "Art des Rezeptes"
        )
    }
    
    private var editSpecials: some View {
        editToggleSection(
            allCases: Special.allCases,
            binding: { $recipe.binding(for: $0) },
            displayName: { $0.displayName },
            header: "Verwendung als..."
        )
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
    
    /// Generic method to create a toggle-based edit section
    private func editToggleSection<T>(
        allCases: [T],
        binding: @escaping (T) -> Binding<Bool>,
        displayName: @escaping (T) -> String,
        header: String
    ) -> some View {
        Section {
            ForEach(allCases.enumerated(), id: \.offset) { index, item in
                Toggle(displayName(item), isOn: binding(item))
            }
        } header: {
            Text(header)
                .fontWeight(.bold)
        }
    }
    
    private func handleSave() {
        try? context.save()
//        isEditing = false
        dismiss()
    }
    
    private func handleCancel() {
        if isNew {
            context.delete(recipe)
            try? context.save()
        } else {
            // Restore original values for existing recipes
            restoreOriginalState()
        }
        dismiss()
    }

    private func saveOriginalState() {
        originalName = recipe.name
        originalPlace = recipe.place
        originalIngredients = recipe.ingredients
        originalPortions = recipe.portions
        originalSeason = recipe.season
        originalCategory = recipe.category
        originalKinds = recipe.kinds
        originalSpecials = recipe.specials
    }
    
    private func restoreOriginalState() {
        recipe.name = originalName
        recipe.place = originalPlace
        recipe.ingredients = originalIngredients
        recipe.portions = originalPortions
        recipe.season = originalSeason ?? recipe.season
        recipe.category = originalCategory ?? recipe.category
        recipe.kinds = originalKinds
        recipe.specials = originalSpecials
    }
}

#Preview {
    RecipeDetailView(recipe: Recipe(name: "Testrezept", place: "Test", ingredients: "100 g Zucker,\n100 g Eiweiß", portions: "Test", season: Season(title: "Test"), category: Category(title: "Test"), photo: nil, kinds: [.fish, .meat], specials: [.soup, .snack]))
}
