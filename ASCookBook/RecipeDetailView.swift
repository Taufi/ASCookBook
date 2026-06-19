//
//  RecipeDetailView.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 28.09.25.
//
import SwiftUI
import SwiftData
import PhotosUI

private struct RecipeEditDraft: Codable {
    let recipeID: PersistentIdentifier
    let name: String
    let portions: String
    let ingredients: String
    let place: String
}

struct RecipeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Bindable var recipe: Recipe
    @State var isEditing: Bool
    private let isNew: Bool
    private let onEditingChanged: (Bool) -> Void
    @Query(sort: [SortDescriptor(\Category.title)]) private var categories: [Category]
    @Query(sort: [SortDescriptor(\Season.title)]) private var seasons: [Season]
    
    // Local editing state to avoid laggy typing
    @State private var editedName: String = ""
    @State private var editedPortions: String = ""
    @State private var editedIngredients: String = ""
    @State private var editedPlace: String = ""
    @State private var hasInitializedEditState: Bool = false
    
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
    @SceneStorage("RecipeDetailView.editDraft") private var storedEditDraft = ""
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var showingCamera = false
    
    // State for adding new categories and seasons
    @State private var showingAddCategoryAlert = false
    @State private var showingAddSeasonAlert = false
    @State private var newCategoryTitle = ""
    @State private var newSeasonTitle = ""
    
    init(
        recipe: Recipe,
        startInEditMode: Bool = false,
        isNew: Bool = false,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self.recipe = recipe
        self.isEditing = startInEditMode
        self.isNew = isNew
        self.onEditingChanged = onEditingChanged
    }
    
    var body : some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                
                imageSection
                
                if isEditing {
                    TextField("Name des Rezeptes", text: $editedName)
                        .textFieldStyle(.roundedBorder)
                    TextField("Portionen", text: $editedPortions)
                        .textFieldStyle(.roundedBorder)
                    editIngredients
                    editCategory
                    editSeason
                    editKinds
                    editSpecials
                    TextField("Quelle des Rezepts", text: $editedPlace)
                        .textFieldStyle(.roundedBorder)
                } else {
                    showPortions
                    showIngredients
                    showCategory
                    showSeason
                    showKinds
                    showSpecials
                    showPlace
                }
            }
            .padding()
        }
        .navigationTitle(isEditing ? editedName : recipe.name)
        .navigationBarBackButtonHidden(isEditing)
        .toolbar { toolBarButtons }
        .onChange(of: selectedItem) { _, newItem in
            Task { await loadImage(from: newItem) }
        }
        .onChange(of: selectedImageData) { _, newData in
            commitPhotoToRecipe(newData)
        }
        .onChange(of: editedName) { _, _ in saveEditDraft() }
        .onChange(of: editedPortions) { _, _ in saveEditDraft() }
        .onChange(of: editedIngredients) { _, _ in saveEditDraft() }
        .onChange(of: editedPlace) { _, _ in saveEditDraft() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                saveEditDraft()
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraPicker(selectedImageData: $selectedImageData)
        }
        .sheet(isPresented: $showingAddCategoryAlert) {
            AddTitledEntitySheet(
                isPresented: $showingAddCategoryAlert,
                text: $newCategoryTitle,
                navigationTitle: "Kategorie hinzufügen",
                sectionHeader: "Neue Kategorie",
                fieldPlaceholder: "Kategoriename",
                footer: "Geben Sie den Namen der neuen Kategorie ein.",
                onAdd: addNewCategory
            )
        }
        .sheet(isPresented: $showingAddSeasonAlert) {
            AddTitledEntitySheet(
                isPresented: $showingAddSeasonAlert,
                text: $newSeasonTitle,
                navigationTitle: "Jahreszeit hinzufügen",
                sectionHeader: "Neue Jahreszeit",
                fieldPlaceholder: "Jahreszeitname",
                footer: "Geben Sie den Namen der neuen Jahreszeit ein.",
                onAdd: addNewSeason
            )
        }
        .onAppear {
            if isEditing && !hasInitializedEditState {
                saveOriginalState()
                if !restoreEditDraft() {
                    syncEditingStateFromRecipe()
                }
            }
        }
    }
    
    private var imageSection: some View {
        RecipeDetailImageSection(
            isEditing: isEditing,
            recipePhoto: recipe.photo,
            selectedImageData: $selectedImageData,
            selectedItem: $selectedItem,
            onRemovePhoto: {
                selectedImageData = nil
                commitPhotoToRecipe(nil)
            },
            onCameraTap: { showingCamera = true }
        )
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
                    if !restoreEditDraft() {
                        syncEditingStateFromRecipe()
                    }
                    isEditing = true
                    onEditingChanged(true)
                    saveEditDraft()
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
        Section {
            Picker("Kategorie", selection: $recipe.category) {
                ForEach(categories, id: \.title) { category in
                    Text(category.title)
                        .tag(category)
                }
            }
            Button(action: {
                showingAddCategoryAlert = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Neue Kategorie hinzufügen")
                }
                .foregroundColor(.blue)
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
            Button(action: {
                showingAddSeasonAlert = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Neue Jahreszeit hinzufügen")
                }
                .foregroundColor(.blue)
            }
        } header: {
            Text("Jahreszeit")
                .fontWeight(.bold)
        }
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
            TextEditor(text: $editedIngredients)
                .frame(height: 300)
                .border(.gray)
        } header: {
            Text("Zutaten und Zubereitung")
                .fontWeight(.bold)
        }
    }
    
    private func handleSave() {
        // Commit edited text fields back to the model
        recipe.name = editedName
        recipe.portions = editedPortions
        recipe.ingredients = editedIngredients
        recipe.place = editedPlace
        
        try? context.save()
        isEditing = false
        clearEditDraft()
        onEditingChanged(false)
        hasInitializedEditState = false
//        dismiss()
    }
    
    private func handleCancel() {
        if isNew {
            recipe.photo = nil //app will crash if photo is not nil
            context.delete(recipe)
            try? context.save()
            dismiss()
        } else {
            restoreOriginalState()
        }
        isEditing = false
        clearEditDraft()
        onEditingChanged(false)
        hasInitializedEditState = false
        selectedImageData = nil
        selectedItem = nil
//        dismiss()
    }
    
    private func syncEditingStateFromRecipe() {
        editedName = recipe.name
        editedPortions = recipe.portions
        editedIngredients = recipe.ingredients
        editedPlace = recipe.place
        hasInitializedEditState = true
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
        try? context.save()
    }

    private func commitPhotoToRecipe(_ data: Data?) {
        guard isEditing else { return }
        recipe.photo = data
        try? context.save()
    }

    private func restoreEditDraft() -> Bool {
        guard let draft = currentEditDraft(), draft.recipeID == recipe.persistentModelID else {
            return false
        }

        editedName = draft.name
        editedPortions = draft.portions
        editedIngredients = draft.ingredients
        editedPlace = draft.place
        hasInitializedEditState = true
        return true
    }

    private func saveEditDraft() {
        guard isEditing else { return }
        let draft = RecipeEditDraft(
            recipeID: recipe.persistentModelID,
            name: editedName,
            portions: editedPortions,
            ingredients: editedIngredients,
            place: editedPlace
        )
        guard let data = try? JSONEncoder().encode(draft) else { return }
        storedEditDraft = data.base64EncodedString()
    }

    private func clearEditDraft() {
        guard currentEditDraft()?.recipeID == recipe.persistentModelID else { return }
        storedEditDraft = ""
    }

    private func currentEditDraft() -> RecipeEditDraft? {
        guard let data = Data(base64Encoded: storedEditDraft) else { return nil }
        return try? JSONDecoder().decode(RecipeEditDraft.self, from: data)
    }
    
    private func addNewCategory() {
        guard !newCategoryTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let newCategory = Category.fetchOrCreate(title: newCategoryTitle.trimmingCharacters(in: .whitespaces), in: context)
        recipe.category = newCategory
        try? context.save()
        newCategoryTitle = ""
    }
    
    private func addNewSeason() {
        guard !newSeasonTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let newSeason = Season.fetchOrCreate(title: newSeasonTitle.trimmingCharacters(in: .whitespaces), in: context)
        recipe.season = newSeason
        try? context.save()
        newSeasonTitle = ""
    }
}

#Preview {
    RecipeDetailView(recipe: Recipe(name: "Testrezept", place: "Test", ingredients: "100 g Zucker,\n100 g Eiweiß", portions: "Test", season: Season(title: "Test"), category: Category(title: "Test"), photo: nil, kinds: [.fish, .meat], specials: [.soup, .snack]))
}
