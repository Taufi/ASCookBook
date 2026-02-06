//
//  RecipeListIndexBar.swift
//  ASCookBook
//

import SwiftUI
import SwiftData

// MARK: - Letter anchors (for ContentView to build index)

enum RecipeListLetterAnchors {
    private static let alphabet: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")

    /// Single pass over recipes to build letter → first index.
    static func anchors(for recipes: [Recipe]) -> [Character: Int] {
        var result: [Character: Int] = [:]
        for (index, recipe) in recipes.enumerated() {
            guard let letter = firstLetter(for: recipe) else { continue }
            if result[letter] == nil {
                result[letter] = index
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

    let anchors: [Character: Int]
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
        if let targetIndex = anchors[letter] {
            withAnimation {
                proxy.scrollTo(targetIndex, anchor: .top)
            }
            return
        }
        for nextLetter in Self.alphabet where nextLetter > letter {
            if let targetIndex = anchors[nextLetter] {
                withAnimation {
                    proxy.scrollTo(targetIndex, anchor: .top)
                }
                return
            }
        }
    }
}
