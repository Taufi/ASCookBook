//
//  Model.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 24.09.25.
//
import SwiftData

@Model
final class Season: TitledModel {
    @Attribute(.unique) var title: String
    @Relationship(inverse: \Recipe.season) var recipes: [Recipe] = []
    
    init(title: String) {
        self.title = title
    }
}
