//
//  Recipe.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 26.09.25.
//
import SwiftData
import SwiftUI

@Model
final class Recipe {
    var name: String
    var place: String
    var ingredients: String
    var portions: String
    var season: Season
    var category: Category
    @Attribute(.externalStorage) var photo: Data?
    var kinds: Kind
    var specials: Special
    
    init(name: String, place: String = "", ingredients: String, portions: String, season: Season, category: Category, photo: Data? = nil, kinds: Kind, specials: Special) {
        self.name = name
        self.place = place
        self.ingredients = ingredients
        self.portions = portions
        self.season = season
        self.category = category
        self.photo = photo
        self.kinds = kinds
        self.specials = specials
    }
}

// Different approach than with kind to test both options
//@MainActor extension Recipe {
//    func binding(for special: Special) -> Binding<Bool> {
//        Binding(
//            get: { self.specials.contains(special) },
//            set: { isOn in
//                    if isOn {
//                    self.specials.insert(special)
//                } else {
//                    self.specials.remove(special)
//                }
//            }
//        )
//    }
//}

