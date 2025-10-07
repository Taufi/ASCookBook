//
//  TitledModel.swift
//  ASCookBook
//
//  Created to provide a shared fetchOrCreate implementation
//

import Foundation
import SwiftData

protocol TitledModel: PersistentModel {
    init(title: String)
    var title: String { get set }
}

extension TitledModel {
    static func fetchOrCreate(title: String, in context: ModelContext) -> Self {
        let descriptor = FetchDescriptor<Self>(
            predicate: #Predicate { $0.title == title }
        )

        if let existing = try? context.fetch(descriptor).first {
            return existing
        } else {
            let instance = Self(title: title)
            context.insert(instance)
            return instance
        }
    }
}


