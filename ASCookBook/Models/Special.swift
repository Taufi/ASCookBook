//
//  Special.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 27.09.25.
//
import SwiftData

@Model
final class Special {
    var title: String
    @Relationship(inverse: \Recipe.specials) var recipes: [Recipe] = []
    
    init(title: String) {
        self.title = title
    }
}
