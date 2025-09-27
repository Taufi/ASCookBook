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
            ContentView()
                .modelContainer(for: [Recipe.self])
        }
    }
}
