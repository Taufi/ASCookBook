//
//  Kind.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 27.09.25.
//

struct Kind: OptionSet, Codable {
    let rawValue: Int
    
    static let vegan = Kind(rawValue: 1 << 0)
    static let vegetarian = Kind(rawValue: 1 << 1)
    static let fish = Kind(rawValue: 1 << 2)
    static let meat = Kind(rawValue: 1 << 3)

    static let allCases: [Kind] = [.vegan, .vegetarian, .fish, .meat]
    
    var displayName: String {
        switch self {
        case .vegan: return "Vegan"
        case .vegetarian: return "Vegetarisch"
        case .fish: return "Fisch"
        case .meat: return "Fleisch"
        default: return "Unknown"
        }
    }
    
    var title: String {
        Kind.allCases.filter { self.contains($0) }.map { $0.displayName }.joined(separator: ", ")
    }
    
}
