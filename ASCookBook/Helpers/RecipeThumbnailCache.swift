//
//  RecipeThumbnailCache.swift
//  ASCookBook
//

import ImageIO
import SwiftData
import UIKit

enum RecipeThumbnailCache {
    /// Matches RecipeRowView (80pt) at up to 2x scale.
    private static let maxThumbnailPixelSize = 160

    private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 300
        cache.totalCostLimit = 50 * 1024 * 1024
        return cache
    }()

    /// Load off the view `body` path — `recipe.photo` and decode must not run synchronously in `body`.
    @MainActor
    static func thumbnail(for recipe: Recipe) async -> UIImage? {
        let recipeID = recipe.persistentModelID
        guard let photoData = recipe.photo else { return nil }

        let key = cacheKey(recipeID: recipeID, photoData: photoData) as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        let maxPixelSize = maxThumbnailPixelSize
        let image = await Task.detached(priority: .utility) {
            downsampledImage(from: photoData, maxPixelSize: maxPixelSize)
        }.value

        guard let image else { return nil }
        cache.setObject(image, forKey: key, cost: memoryCost(for: image))
        return image
    }

    nonisolated private static func downsampledImage(from data: Data, maxPixelSize: Int) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailWithTransform: true,
        ]
        guard
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    private static func memoryCost(for image: UIImage) -> Int {
        guard let cgImage = image.cgImage else {
            return Int(image.size.width * image.size.height * 4)
        }
        return cgImage.bytesPerRow * cgImage.height
    }

    private static func cacheKey(recipeID: PersistentIdentifier, photoData: Data) -> String {
        var hasher = Hasher()
        hasher.combine(recipeID)
        hasher.combine(photoData.count)
        if !photoData.isEmpty {
            hasher.combine(photoData[0])
            if photoData.count > 2 {
                hasher.combine(photoData[photoData.count / 2])
                hasher.combine(photoData[photoData.count - 1])
            }
        }
        return String(hasher.finalize())
    }
}
