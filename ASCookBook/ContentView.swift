//
//  ContentView.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 24.09.25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Recipe.name)]) private var recipes: [Recipe]
    @State private var searchText: String = ""
    @State private var addedRecipe: Recipe?
    @State private var showingAdvancedSearch = false
    
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var recipeImageData: Data?
    
    @State private var showingTextRecipeSheet = false
    @State private var pendingRecipeText: String?
    
    // Progress tracking for recipe processing
    @State private var isProcessingRecipe = false
    @State private var processingProgress: Double = 0.0
    @State private var processingMessage = ""
    
    // Error handling
    @State private var showingError = false
    @State private var errorMessage = ""

    private let alphabet: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    
    /// Single pass over recipes to build letter → first index. Use this once per update and pass the result down.
    private func letterAnchors(for recipes: [Recipe]) -> [Character: Int] {
        var result: [Character: Int] = [:]
        for (index, recipe) in recipes.enumerated() {
            guard let letter = firstLetter(for: recipe) else { continue }
            if result[letter] == nil {
                result[letter] = index
            }
        }
        return result
    }
    
    var filteredRecipes: [Recipe] {
        if searchText.isEmpty {
            return recipes
        } else {
            return recipes.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.ingredients.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        let progressView = Group {
            if isProcessingRecipe {
                VStack(spacing: 16) {
                    ProgressView(value: processingProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(maxWidth: 200)
                    Text(processingMessage)
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
            // Index bar path: compute anchors once and pass down
            let anchors = letterAnchors(for: filteredRecipes)
            ScrollViewReader { proxy in
                ZStack(alignment: .topTrailing) {
                    VStack {
                        progressView
                        List {
                            ForEach(Array(filteredRecipes.enumerated()), id: \.element.id) { index, recipe in
                                recipeRow(recipe: recipe)
                                    .id(index)
                            }
                            .onDelete(perform: deleteRecipes)
                        }
                        .safeAreaInset(edge: .trailing, spacing: 0) {
                            Color.clear.frame(width: 8) //28
                        }
                    }
                    indexBar(anchors: anchors, proxy: proxy)
                }
            }
        } else {
            // Search active: simple list, no index or anchors
            VStack {
                progressView
                List {
                    ForEach(filteredRecipes) { recipe in
                        recipeRow(recipe: recipe)
                    }
                    .onDelete(perform: deleteRecipes)
                }
            }
        }
    }
    
    private func recipeRow(recipe: Recipe) -> some View {
        NavigationLink(value: recipe) {
            HStack(alignment: .top, spacing: 12) {
                if let photoData = recipe.photo, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image("Plate")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                VStack(alignment: .leading) {
                    Text(recipe.name).bold()
                    Text(recipe.category.title)
                        .font(.subheadline).foregroundStyle(.secondary)
                    Text(recipe.kinds.title)
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
        .sheet(isPresented: $showingPhotoLibrary) {
            PhotoLibraryPicker(selectedImageData: $recipeImageData)
        }
        .sheet(isPresented: $showingTextRecipeSheet) {
            RecipeFromTextView(pendingRecipeText: $pendingRecipeText)
        }
        .onChange(of: recipeImageData) {
            Task { await recipeFromPhoto() }
        }
        .onChange(of: pendingRecipeText) { _, newValue in
            guard let text = newValue, !text.isEmpty else { return }
            Task { await recipeFromText(text) }
        }
        .alert("Fehler beim Verarbeiten", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func recipeFromPhoto() async {
        guard let imageData = recipeImageData else { return }
        
        // Start processing
        await MainActor.run {
            isProcessingRecipe = true
            processingProgress = 0.0
            processingMessage = "Bild wird analysiert..."
        }
        
        let service = TextRecognitionService()
        
        do {
            // Update progress for text recognition
            await MainActor.run {
                processingProgress = 0.3
                processingMessage = "Text wird erkannt..."
            }
            
            let recipeResponse = try await service.extractRecipe(from: imageData)
            
            // Update progress for recipe processing
            await MainActor.run {
                processingProgress = 0.7
                processingMessage = "Rezept wird verarbeitet..."
            }

            let ingredientsBlock = recipeResponse.ingredients.joined(separator: "\n")
            let instructions = [ingredientsBlock, recipeResponse.instructions]
                .compactMap { $0 }
                .joined(separator: "\n\n")
            
            // Update progress for saving
            await MainActor.run {
                processingProgress = 0.9
                processingMessage = "Rezept wird gespeichert..."
            }
            
            let newRecipe = Recipe(
                name: recipeResponse.title,
                place: "",
                ingredients: instructions,
                portions: recipeResponse.servings ?? "",
                season: Season.fetchOrCreate(title: "immer", in: context),
                category: Category.fetchOrCreate(title: "Hauptspeisen", in: context),
                photo: imageData,
                kinds: Kind(rawValue: 1),
                specials: Special(rawValue: 0),
            )
            context.insert(newRecipe)
            addedRecipe = newRecipe
            try? context.save()
            
            // Complete processing
            await MainActor.run {
                processingProgress = 1.0
                processingMessage = "Fertig!"
            }
            
            // Hide progress after a short delay
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            await MainActor.run {
                isProcessingRecipe = false
                processingProgress = 0.0
                processingMessage = ""
            }
            
        } catch {
            print("Error extracting recipe from photo: \(error)")
            
            // Reset progress state on error
            await MainActor.run {
                isProcessingRecipe = false
                processingProgress = 0.0
                processingMessage = ""
                
                // Show user-friendly error message
                if let nsError = error as NSError? {
                    switch nsError.domain {
                    case "TextRecognitionService":
                        switch nsError.code {
                        case 1:
                            errorMessage = "Das Bild konnte nicht verarbeitet werden. Bitte versuchen Sie es mit einem anderen Foto."
                        case 2:
                            errorMessage = "Das Bildformat wird nicht unterstützt. Bitte verwenden Sie ein anderes Foto."
                        case 3:
                            errorMessage = "Kein Text im Bild gefunden. Bitte fotografieren Sie ein Rezept mit lesbarem Text."
                        default:
                            errorMessage = "Fehler bei der Texterkennung: \(nsError.localizedDescription)"
                        }
                    case "OpenAIService":
                        errorMessage = "Fehler beim Verarbeiten des Rezepts. Code: \(nsError.code). Bitte überprüfen Sie Ihre Internetverbindung und versuchen Sie es erneut."
                    default:
                        errorMessage = "Ein unbekannter Fehler ist aufgetreten: \(nsError.localizedDescription)"
                    }
                } else {
                    errorMessage = "Ein Fehler ist aufgetreten: \(error.localizedDescription)"
                }
                
                showingError = true
            }
        }
    }
    
    private func recipeFromText(_ text: String) async {
        await MainActor.run { pendingRecipeText = nil }
        
        await MainActor.run {
            isProcessingRecipe = true
            processingProgress = 0.5
            processingMessage = "Rezept wird verarbeitet..."
        }
        
        let service = TextRecognitionService()
        
        do {
            let recipeResponse = try await service.recipeFromText(text)
            
            await MainActor.run {
                processingProgress = 0.75
                processingMessage = "Rezept wird gespeichert..."
                let ingredientsBlock = recipeResponse.ingredients.joined(separator: "\n")
                let instructions = [ingredientsBlock, recipeResponse.instructions]
                    .compactMap { $0 }
                    .joined(separator: "\n\n")
                let newRecipe = Recipe(
                    name: recipeResponse.title,
                    place: "",
                    ingredients: instructions,
                    portions: recipeResponse.servings ?? "",
                    season: Season.fetchOrCreate(title: "immer", in: context),
                    category: Category.fetchOrCreate(title: "Hauptspeisen", in: context),
                    photo: nil,
                    kinds: Kind(rawValue: 1),
                    specials: Special(rawValue: 0),
                )
                context.insert(newRecipe)
                addedRecipe = newRecipe
                try? context.save()
                processingProgress = 1.0
                processingMessage = "Fertig!"
            }
            
            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                isProcessingRecipe = false
                processingProgress = 0.0
                processingMessage = ""
            }
        } catch {
            await MainActor.run {
                isProcessingRecipe = false
                processingProgress = 0.0
                processingMessage = ""
                if let nsError = error as NSError? {
                    switch nsError.domain {
                    case "OpenAIService":
                        errorMessage = "Fehler beim Verarbeiten des Rezepts. Code: \(nsError.code). Bitte überprüfen Sie Ihre Internetverbindung und versuchen Sie es erneut."
                    default:
                        errorMessage = "Ein unbekannter Fehler ist aufgetreten: \(nsError.localizedDescription)"
                    }
                } else {
                    errorMessage = "Ein Fehler ist aufgetreten: \(error.localizedDescription)"
                }
                showingError = true
            }
        }
    }
    
    private func firstLetter(for recipe: Recipe) -> Character? {
        let trimmed = recipe.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return nil }
        
        let mapped: String
        switch first {
        case "Ä", "ä":
            mapped = "A"
        case "Ö", "ö":
            mapped = "O"
        case "Ü", "ü":
            mapped = "U"
        case "ß":
            mapped = "S"
        default:
            mapped = String(first)
        }
        
        let upper = mapped.uppercased()
        guard let letter = upper.first,
              ("A"..."Z").contains(String(letter)) else {
            return nil
        }
        
        return letter
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
    
    //KD TODO Error: deletes wrong recipes when in search mode
    private func deleteRecipes(at offsets: IndexSet) {
        for index in offsets {
            context.delete(filteredRecipes[index])
        }
    }
    
    @ViewBuilder
    private func indexBar(anchors: [Character: Int], proxy: ScrollViewProxy) -> some View {
        let availableLetters = anchors.keys.sorted()
        VStack {
            ForEach(alphabet, id: \.self) { letter in
                Button {
                    scrollToLetter(letter, anchors: anchors, using: proxy)
                } label: {
                    Text(String(letter))
                        .font(.caption2)
                        .foregroundStyle(availableLetters.contains(letter) ? .secondary : .tertiary)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 4)
                }
                .disabled(!availableLetters.contains(letter))
            }
        }
        .padding(.trailing, 4)
        .padding(.vertical, 8)
    }
    
    private func scrollToLetter(_ letter: Character, anchors: [Character: Int], using proxy: ScrollViewProxy) {
        if let targetIndex = anchors[letter] {
            withAnimation {
                proxy.scrollTo(targetIndex, anchor: .top)
            }
            return
        }
        for nextLetter in alphabet where nextLetter > letter {
            if let targetIndex = anchors[nextLetter] {
                withAnimation {
                    proxy.scrollTo(targetIndex, anchor: .top)
                }
                return
            }
        }
    }
}

#Preview {
    ContentView()
}

