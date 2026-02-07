//
//  RecipeDetailSectionHelpers.swift
//  ASCookBook
//

import SwiftUI

extension View {
    /// Displays a section with optional conditional rendering (e.g. for recipe read-only fields).
    func showSection(content: String, header: String, condition: Bool = true) -> some View {
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

    /// Creates a toggle-based edit section for option-set style values (e.g. Kind, Special).
    func editToggleSection<T>(
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
