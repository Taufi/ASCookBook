//
//  ContentView.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 24.09.25.
//

import SwiftUI
import SwiftData
import PhotosUI

struct RecipeRoute: Hashable, Codable {
    let recipeID: PersistentIdentifier
    var startInEditMode: Bool
    let isNew: Bool

    init(recipe: Recipe, startInEditMode: Bool = false, isNew: Bool = false) {
        self.recipeID = recipe.persistentModelID
        self.startInEditMode = startInEditMode
        self.isNew = isNew
    }
}

struct RecipesLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Lade Rezepte")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Recipe.name)]) private var recipes: [Recipe]
    @State private var isLoadingRecipes = true
    @State private var navigationPath: [RecipeRoute] = []
    @State private var hasRestoredNavigationPath = false
    @SceneStorage("ContentView.navigationPath") private var storedNavigationPath = ""
    @State private var searchText: String = ""
    @State private var showingAdvancedSearch = false

    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var photoLibraryItem: PhotosPickerItem?
    @State private var recipeImageData: Data?

    @State private var showingTextRecipeSheet = false
    @State private var pendingRecipeText: String?

    @State private var importViewModel = RecipeImportViewModel()
    @State private var recipeIDToScrollTo: PersistentIdentifier?

    var filteredRecipes: [Recipe] {
        if searchText.isEmpty {
            return recipes
        } else {
            return recipes.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
                    || $0.ingredients.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    @ViewBuilder
    private var recipeListContent: some View {
        let progressView = Group {
            if importViewModel.isProcessingRecipe {
                VStack(spacing: 16) {
                    ProgressView(value: importViewModel.processingProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(maxWidth: 200)
                    Text(importViewModel.processingMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }

        let showIndexBar = searchText.isEmpty
        ScrollViewReader { proxy in
            ZStack(alignment: .topTrailing) {
                VStack {
                    progressView
                    recipeList(includeIndexBarInset: showIndexBar)
                }
                if showIndexBar {
                    RecipeListIndexBar(
                        anchors: RecipeListLetterAnchors.anchors(for: filteredRecipes),
                        proxy: proxy
                    )
                }
            }
            .onChange(of: recipeIDToScrollTo) { _, recipeID in
                scrollToRecipeIfNeeded(recipeID, proxy: proxy)
            }
        }
    }

    @ViewBuilder
    private func recipeList(includeIndexBarInset: Bool) -> some View {
        let list = List {
            ForEach(filteredRecipes) { recipe in
                RecipeRowView(recipe: recipe)
                    .id(recipe.persistentModelID)
            }
            .onDelete(perform: deleteRecipes)
        }

        if includeIndexBarInset {
            list.safeAreaInset(edge: .trailing, spacing: 0) {
                Color.clear.frame(width: 8)
            }
        } else {
            list
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath)  {
            recipeListContent
                .task {
                    await waitForRecipesQuery()
                }
                .task {
                    if recipes.isEmpty {
                        if let dbURL = Bundle.main.url(forResource: "CookBook", withExtension: "sqlite") {
                            importLegacyDatabase(dbPath: dbURL.path, context: context)
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Suche Rezepte")
                .navigationTitle("Rezepte")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(action: addNewRecipe) {
                                Label("Neues Rezept", systemImage: "plus")
                            }
                            Button(action: { showingAdvancedSearch = true }) {
                                Label("Erweiterte Suche", systemImage: "magnifyingglass")
                            }
                            Button(action: { showingCamera = true }) {
                                Label("Rezept fotografieren", systemImage: "camera.on.rectangle")
                            }
                            Button(action: { showingPhotoLibrary = true }) {
                                Label("Rezeptfoto aus Galerie", systemImage: "photo.on.rectangle")
                            }
                            Button(action: { showingTextRecipeSheet = true }) {
                                Label("Rezept aus Text", systemImage: "doc.text")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                .navigationDestination(for: RecipeRoute.self) { route in
                    if let recipe = context.registeredModel(for: route.recipeID) as Recipe? {
                        RecipeDetailView(
                            recipe: recipe,
                            startInEditMode: route.startInEditMode,
                            isNew: route.isNew,
                            onEditingChanged: { isEditing in
                                updateNavigationRoute(for: route.recipeID, isEditing: isEditing)
                            },
                            onDiscardNewRecipe: discardNewRecipe
                        )
                    } else {
                        Text("Rezept nicht gefunden")
                            .onAppear {
                                removeInvalidRoutes()
                            }
                    }
                }
        }
        .overlay {
            if isLoadingRecipes {
                RecipesLoadingView()
            }
        }
        .onAppear(perform: restoreNavigationPathIfNeeded)
        .onChange(of: navigationPath) { oldPath, newPath in
            saveNavigationPath(newPath)
            if newPath.count < oldPath.count, let popped = oldPath.last {
                recipeIDToScrollTo = popped.recipeID
            }
        }
        .sheet(isPresented: $showingAdvancedSearch) {
            AdvancedSearchView(recipes: recipes)
        }
        .sheet(isPresented: $showingCamera) {
            CameraPicker(selectedImageData: $recipeImageData)
        }
        .sheet(isPresented: $showingTextRecipeSheet) {
            RecipeFromTextView(pendingRecipeText: $pendingRecipeText)
        }
        .photosPicker(
            isPresented: $showingPhotoLibrary,
            selection: $photoLibraryItem,
            matching: .images
        )
        .onChange(of: photoLibraryItem) { _, newItem in
            Task { await loadPhotoFromLibrary(newItem) }
        }
        .onChange(of: recipeImageData) {
            Task {
                guard let imageData = recipeImageData else { return }
                recipeImageData = nil
                await importViewModel.recipeFromPhoto(
                    imageData: imageData,
                    context: context,
                    onRecipeCreated: { openRecipe($0, startInEditMode: true, isNew: true) }
                )
            }
        }
        .onChange(of: pendingRecipeText) { _, newValue in
            guard let text = newValue, !text.isEmpty else { return }
            pendingRecipeText = nil
            Task {
                await importViewModel.recipeFromText(text, context: context) {
                    openRecipe($0, startInEditMode: true, isNew: true)
                }
            }
        }
        .alert("Fehler beim Verarbeiten", isPresented: $importViewModel.showingError) {
            Button("OK") { }
        } message: {
            Text(importViewModel.errorMessage)
        }
    }

    private func waitForRecipesQuery() async {
        let totalCount = (try? context.fetchCount(FetchDescriptor<Recipe>())) ?? 0
        guard totalCount > 0 else {
            isLoadingRecipes = false
            return
        }
        while recipes.isEmpty {
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(16))
        }
        isLoadingRecipes = false
    }

    private func loadPhotoFromLibrary(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self) {
            await MainActor.run {
                recipeImageData = data
                photoLibraryItem = nil
            }
        }
    }

    private func addNewRecipe() {
        let season = Season.fetchOrCreate(title: "immer", in: context)
        let category = Category.fetchOrCreate(title: "Hauptspeisen", in: context)
        let newRecipe = Recipe(
            name: "Neues Rezept",
            place: "",
            ingredients: "",
            portions: "",
            season: season,
            category: category,
            photo: nil,
            kinds: Kind(rawValue: 1),
            specials: Special(rawValue: 0),
        )
        context.insert(newRecipe)
        try? context.save()
        openRecipe(newRecipe, startInEditMode: true, isNew: true)
    }

    // KD TODO Error: deletes wrong recipes when in search mode
    private func deleteRecipes(at offsets: IndexSet) {
        for index in offsets {
            context.delete(filteredRecipes[index])
        }
    }

    private func openRecipe(_ recipe: Recipe, startInEditMode: Bool, isNew: Bool = false) {
        navigationPath.append(RecipeRoute(recipe: recipe, startInEditMode: startInEditMode, isNew: isNew))
    }

    private func updateNavigationRoute(for recipeID: PersistentIdentifier, isEditing: Bool) {
        guard let index = navigationPath.lastIndex(where: { $0.recipeID == recipeID }) else { return }
        navigationPath[index].startInEditMode = isEditing
    }

    private func restoreNavigationPathIfNeeded() {
        guard !hasRestoredNavigationPath else { return }
        hasRestoredNavigationPath = true

        guard
            let data = Data(base64Encoded: storedNavigationPath),
            let restoredPath = try? JSONDecoder().decode([RecipeRoute].self, from: data)
        else {
            return
        }
        navigationPath = validRoutes(from: restoredPath)
    }

    private func validRoutes(from routes: [RecipeRoute]) -> [RecipeRoute] {
        routes.filter { (context.registeredModel(for: $0.recipeID) as Recipe?) != nil }
    }

    private func removeInvalidRoutes() {
        let validPath = validRoutes(from: navigationPath)
        guard validPath.count != navigationPath.count else { return }
        navigationPath = validPath
    }

    private func discardNewRecipe(_ recipeID: PersistentIdentifier) {
        navigationPath.removeAll { $0.recipeID == recipeID }

        Task { @MainActor in
            guard let recipe = context.registeredModel(for: recipeID) as Recipe? else { return }
            recipe.photo = nil
            context.delete(recipe)
            try? context.save()
        }
    }

    private func saveNavigationPath(_ path: [RecipeRoute]) {
        guard let data = try? JSONEncoder().encode(path) else { return }
        storedNavigationPath = data.base64EncodedString()
    }

    private func scrollToRecipeIfNeeded(_ recipeID: PersistentIdentifier?, proxy: ScrollViewProxy) {
        guard let recipeID else { return }
        recipeIDToScrollTo = nil
        guard filteredRecipes.contains(where: { $0.persistentModelID == recipeID }) else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(50))
            withAnimation {
                proxy.scrollTo(recipeID, anchor: .center)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Recipe.self, Category.self, Season.self])
}
