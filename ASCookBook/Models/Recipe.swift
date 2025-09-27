//
//  Recipe.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 26.09.25.
//
import SwiftData

@Model
final class Recipe {
    var name: String
    var place: String?
    var ingredients: String
    var portions: String
    var season: Season?
    var category: Category?
    var photoId: Int?
    
    init(name: String, place: String? = nil, ingredients: String, portions: String, season: Season? = nil, category: Category? = nil, photoId: Int? = nil) {
        self.name = name
        self.place = place
        self.ingredients = ingredients
        self.portions = portions
        self.season = season
        self.category = category
        self.photoId = photoId
    }
}
