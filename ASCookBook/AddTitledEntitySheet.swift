//
//  AddTitledEntitySheet.swift
//  ASCookBook
//

import SwiftUI

/// Reusable sheet to add a single titled entity (e.g. category, season) via one text field.
struct AddTitledEntitySheet: View {
    @Binding var isPresented: Bool
    @Binding var text: String
    let navigationTitle: String
    let sectionHeader: String
    let fieldPlaceholder: String
    let footer: String
    let onAdd: () -> Void

    private var isAddDisabled: Bool {
        text.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(fieldPlaceholder, text: $text)
                } header: {
                    Text(sectionHeader)
                } footer: {
                    Text(footer)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        text = ""
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hinzufügen") {
                        onAdd()
                        isPresented = false
                    }
                    .disabled(isAddDisabled)
                }
            }
        }
        .presentationDetents([.height(200)])
    }
}

#Preview("Add category") {
    struct PreviewWrapper: View {
        @State private var isPresented = true
        @State private var text = ""
        var body: some View {
            AddTitledEntitySheet(
                isPresented: $isPresented,
                text: $text,
                navigationTitle: "Kategorie hinzufügen",
                sectionHeader: "Neue Kategorie",
                fieldPlaceholder: "Kategoriename",
                footer: "Geben Sie den Namen der neuen Kategorie ein.",
                onAdd: { }
            )
        }
    }
    return PreviewWrapper()
}
