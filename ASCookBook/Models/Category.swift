//
//  Category.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 27.09.25.
//
import SwiftData

@Model
final class Category: TitledModel {
    @Attribute(.unique) var title: String
    @Relationship(inverse: \Recipe.category) var recipes: [Recipe] = []
    
    init(title: String) {
        self.title = title
    }
}
