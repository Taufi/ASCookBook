//
//  RecipeDetailImageSection.swift
//  ASCookBook
//

import SwiftUI
import PhotosUI

struct RecipeDetailImageSection: View {
    let isEditing: Bool
    let recipePhoto: Data?
    @Binding var selectedImageData: Data?
    @Binding var selectedItem: PhotosPickerItem?
    let onRemovePhoto: () -> Void
    let onCameraTap: () -> Void

    /// In edit mode, show selected image or recipe photo; otherwise show recipe photo only.
    private var displayedImageData: Data? {
        selectedImageData ?? recipePhoto
    }

    var body: some View {
        if isEditing {
            editModeContent
        } else {
            readModeContent
        }
    }

    private var editModeContent: some View {
        VStack(spacing: 12) {
            if let data = displayedImageData, let uiImage = UIImage(data: data) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .cornerRadius(12)
                        .clipped()

                    Button(action: onRemovePhoto) {
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

            HStack(spacing: 16) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("Fotoalbum", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button(action: onCameraTap) {
                    Label("Kamera", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
    }

    @ViewBuilder
    private var readModeContent: some View {
        if let data = recipePhoto, let uiImage = UIImage(data: data) {
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

#Preview("Read mode") {
    RecipeDetailImageSection(
        isEditing: false,
        recipePhoto: nil,
        selectedImageData: .constant(nil),
        selectedItem: .constant(nil),
        onRemovePhoto: { },
        onCameraTap: { }
    )
    .padding()
}

#Preview("Edit mode") {
    RecipeDetailImageSection(
        isEditing: true,
        recipePhoto: nil,
        selectedImageData: .constant(nil),
        selectedItem: .constant(nil),
        onRemovePhoto: { },
        onCameraTap: { }
    )
    .padding()
}
