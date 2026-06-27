//
//  RecipeListIndexBar.swift
//  ASCookBook
//

import SwiftUI
import SwiftData

// MARK: - Letter anchors (for ContentView to build index)

enum RecipeListLetterAnchors {
    private static let alphabet: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")

    /// Single pass over recipes to build letter → first recipe ID.
    static func anchors(for recipes: [Recipe]) -> [Character: PersistentIdentifier] {
        var result: [Character: PersistentIdentifier] = [:]
        for recipe in recipes {
            guard let letter = firstLetter(for: recipe) else { continue }
            if result[letter] == nil {
                result[letter] = recipe.persistentModelID
            }
        }
        return result
    }

    private static func firstLetter(for recipe: Recipe) -> Character? {
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
}

// MARK: - Index bar view

struct RecipeListIndexBar: View {
    private static let alphabet: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")

    let anchors: [Character: PersistentIdentifier]
    let proxy: ScrollViewProxy

    var body: some View {
        let availableLetters = anchors.keys.sorted()
        VStack {
            ForEach(Self.alphabet, id: \.self) { letter in
                Button {
                    scrollToLetter(letter)
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

    private func scrollToLetter(_ letter: Character) {
        let targetID: PersistentIdentifier?
        if let recipeID = anchors[letter] {
            targetID = recipeID
        } else {
            targetID = Self.alphabet
                .filter { $0 > letter }
                .compactMap { anchors[$0] }
                .first
        }
        guard let targetID else { return }
        withAnimation {
            proxy.scrollTo(targetID, anchor: .top)
        }
    }
}
