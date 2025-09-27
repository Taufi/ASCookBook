//
//  Kind.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 27.09.25.
//
import SwiftData

@Model
final class Kind {
    var title: String
    @Relationship(inverse: \Recipe.kinds) var recipes: [Recipe] = []
    
    init(title: String) {
        self.title = title
    }
}
