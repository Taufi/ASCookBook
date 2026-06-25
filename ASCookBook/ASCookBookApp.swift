//
//  ASCookBookApp.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 24.09.25.
//

import SwiftUI
import SwiftData

@main
struct ASCookBookApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}

private struct AppRootView: View {
    @State private var isModelContainerReady = false

    var body: some View {
        Group {
            if isModelContainerReady {
                ContentView()
                    .modelContainer(for: [Recipe.self, Category.self, Season.self])
            } else {
                RecipesLoadingView()
            }
        }
        .task {
            await Task.yield()
            isModelContainerReady = true
        }
    }
}
