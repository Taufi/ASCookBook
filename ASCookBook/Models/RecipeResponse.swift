//
//  RecipeResponse.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 19.10.25.
//
import Foundation

struct RecipeResponse: Decodable, Equatable {
    let title: String
    let ingredients: [String]
    let instructions: String
    let servings: String?
}
