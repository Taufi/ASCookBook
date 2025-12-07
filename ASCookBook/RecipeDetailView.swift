//
//  RecipeDetailView.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 28.09.25.
//
import SwiftUI
import SwiftData
import PhotosUI

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
    @State private var originalPhoto: Data?
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var showingCamera = false
    
    init(recipe: Recipe, startInEditMode: Bool = false) {
        self.recipe = recipe
        self.isEditing = startInEditMode
        self.isNew = startInEditMode
    }
    
    var body : some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                
                imageSection
                
                if isEditing {
                    TextField("Name des Rezeptes", text: $recipe.name)
                        .textFieldStyle(.roundedBorder)
                    editIngredients
                    editCategory
                    editSeason
                    editKinds
                    editSpecials
                    TextField("Quelle des Rezepts", text: $recipe.place)
                        .textFieldStyle(.roundedBorder)
                    TextField("Portionen", text: $recipe.portions)
                        .textFieldStyle(.roundedBorder)
                } else {
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
        .navigationBarBackButtonHidden(isEditing)
        .toolbar { toolBarButtons }
        .onChange(of: selectedItem) { _, newItem in
            Task { await loadImage(from: newItem) }
        }
        .sheet(isPresented: $showingCamera) {
            CameraPicker(selectedImageData: $selectedImageData)
        }
    }
    
    @ViewBuilder
    private var imageSection: some View {
        let image = selectedImageData ?? recipe.photo
        if isEditing {
            VStack(spacing: 12) {
                // Image display area
                if let data = image, let uiImage = UIImage(data: data) {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
//                        .frame(height: 200)
                            .cornerRadius(12)
                            .clipped()
                        
                        Button(action: {
                            selectedImageData = nil
                            recipe.photo = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                                .padding(8)
                        }
                    }
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 200)
                        Text("Kein Bild ausgewählt")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Action buttons
                HStack(spacing: 16) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("Fotoalbum", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Button(action: { showingCamera = true }) {
                        Label("Kamera", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
        } else {
            if let data = recipe.photo, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .cornerRadius(12)
            } else {
                Image("Plate")
                    .resizable()
                    .scaledToFit()
                    .padding()
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolBarButtons: some ToolbarContent {
        if isEditing {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Änderungen verwerfen") {
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
    
    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self) {
            await MainActor.run {
                selectedImageData = data
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
    
    private func handleSave() {
        // Save the selected image to the recipe if one was selected
        if let imageData = selectedImageData {
            recipe.photo = imageData
        }
        try? context.save()
        isEditing = false
//        dismiss()
    }
    
    private func handleCancel() {
        if isNew {
            recipe.photo = nil //app will crash if photo is not nil
            context.delete(recipe)
            try? context.save()
            dismiss()
        } else {
            // Restore original values for existing recipes
            restoreOriginalState()
        }
        // Reset the selected image data
        selectedImageData = nil
        selectedItem = nil
        isEditing = false
//        dismiss()
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
        originalPhoto = recipe.photo
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
        recipe.photo = originalPhoto
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
}

#Preview {
    RecipeDetailView(recipe: Recipe(name: "Testrezept", place: "Test", ingredients: "100 g Zucker,\n100 g Eiweiß", portions: "Test", season: Season(title: "Test"), category: Category(title: "Test"), photo: nil, kinds: [.fish, .meat], specials: [.soup, .snack]))
}
