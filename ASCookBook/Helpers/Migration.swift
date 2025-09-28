//
//  Migration.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 24.09.25.
//
import SwiftData

func importLegacyDatabase(dbPath: String, context: ModelContext) {
    var seasonMap: [Int: Season] = [:]
    var categoryMap: [Int: Category] = [:]
    
    // images where string in recipe table before. Here I create a join table
    var kindMap = [String: Kind]()
    var kind = Kind(title: "Fisch")
    kindMap["Fisch"] = kind
    kind = Kind(title: "Fleisch")
    kindMap["Fleisch"] = kind
    kind = Kind(title: "Vegetarisch")
    kindMap["Vegetarisch"] = kind
    kind = Kind(title: "Vegan")
    kindMap["Vegan"] = kind
    
    // three special titles where attrubutes in recipe table before. Here I create a join table.
    var specialMap = [Int: Special]()
    specialMap[0] = Special(title: "AmuseGueule")
    specialMap[1] = Special(title: "Snack")
    specialMap[2] = Special(title: "Suppe")
    
    
    for (id, title) in readSeasons(dbPath: dbPath) {
        let season = Season(title: title)
        seasonMap[id] = season
        context.insert(season)
    }
    
    for (id, title) in readCategories(dbPath: dbPath) {
        let category = Category(title: title)
        categoryMap[id] = category
        context.insert(category)
    }
    
    for (_, name, place, portions, ingredients, seasonId, categoryId, photoId, kindString, amusegueule, snack, soup) in readRecipes(dbPath: dbPath) {
        let season = seasonMap[seasonId]
        let category = categoryMap[categoryId]
        let recipe = Recipe(name: name, place: place, ingredients: ingredients, portions: portions, season: season, category: category, photoId: photoId)
        if kindString != nil {
            if let kind = kindMap[kindString!] {
                recipe.kinds.append(kind)
            }
        }
        if amusegueule == 1 {
            recipe.specials.append(specialMap[0]!)
        }
        if snack == 1 {
            recipe.specials.append(specialMap[1]!)
        }
        if soup == 1 {
            recipe.specials.append(specialMap[2]!)
        }
        context.insert(recipe)
    }
    
    readImages(dbPath: dbPath)
    
}
