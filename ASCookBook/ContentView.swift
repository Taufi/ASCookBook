//
//  ContentView.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 24.09.25.
//

import SwiftUI
import SwiftData
import PhotosUI

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Recipe.name)]) private var recipes: [Recipe]
    @State private var searchText: String = ""
    @State private var addedRecipe: Recipe?
    @State private var showingAdvancedSearch = false

    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var photoLibraryItem: PhotosPickerItem?
    @State private var recipeImageData: Data?

    @State private var showingTextRecipeSheet = false
    @State private var pendingRecipeText: String?

    @State private var importViewModel = RecipeImportViewModel()

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
    private var mainContent: some View {
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

        if searchText.isEmpty {
            let anchors = RecipeListLetterAnchors.anchors(for: filteredRecipes)
            ScrollViewReader { proxy in
                ZStack(alignment: .topTrailing) {
                    VStack {
                        progressView
                        List {
                            ForEach(Array(filteredRecipes.enumerated()), id: \.element.id) { index, recipe in
                                RecipeRowView(recipe: recipe)
                                    .id(index)
                            }
                            .onDelete(perform: deleteRecipes)
                        }
                        .safeAreaInset(edge: .trailing, spacing: 0) {
                            Color.clear.frame(width: 8)
                        }
                    }
                    RecipeListIndexBar(anchors: anchors, proxy: proxy)
                }
            }
        } else {
            VStack {
                progressView
                List {
                    ForEach(filteredRecipes) { recipe in
                        RecipeRowView(recipe: recipe)
                    }
                    .onDelete(perform: deleteRecipes)
                }
            }
        }
    }

    var body: some View {
        NavigationStack {
            mainContent
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
                .navigationDestination(for: Recipe.self) { recipe in
                    RecipeDetailView(recipe: recipe, startInEditMode: false)
                }
                .navigationDestination(item: $addedRecipe) { recipe in
                    RecipeDetailView(recipe: recipe, startInEditMode: true)
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
                await importViewModel.recipeFromPhoto(
                    imageData: imageData,
                    context: context,
                    onRecipeCreated: { addedRecipe = $0 }
                )
            }
        }
        .onChange(of: pendingRecipeText) { _, newValue in
            guard let text = newValue, !text.isEmpty else { return }
            pendingRecipeText = nil
            Task {
                await importViewModel.recipeFromText(text, context: context) { addedRecipe = $0 }
            }
        }
        .alert("Fehler beim Verarbeiten", isPresented: $importViewModel.showingError) {
            Button("OK") { }
        } message: {
            Text(importViewModel.errorMessage)
        }
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
        let newRecipe = Recipe(
            name: "Neues Rezept",
            place: "",
            ingredients: "",
            portions: "",
            season: Season.fetchOrCreate(title: "immer", in: context),
            category: Category.fetchOrCreate(title: "Hauptspeisen", in: context),
            photo: nil,
            kinds: Kind(rawValue: 1),
            specials: Special(rawValue: 0),
        )
        context.insert(newRecipe)
        addedRecipe = newRecipe
        try? context.save()
    }

    // KD TODO Error: deletes wrong recipes when in search mode
    private func deleteRecipes(at offsets: IndexSet) {
        for index in offsets {
            context.delete(filteredRecipes[index])
        }
    }
}

#Preview {
    ContentView()
}
