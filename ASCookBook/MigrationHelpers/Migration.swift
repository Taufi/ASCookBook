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
        let recipe = Recipe(name: name, place: place, ingredients: ingredients, portions: portions, season: season, category: category, photoId: photoId, kinds: [])
        
        if kindString != nil {
            switch kindString! {
                case "Vegan":
                    recipe.kinds = Kind(rawValue: 1 << 0)
                case "Vegetarisch":
                recipe.kinds = Kind(rawValue: 1 << 1)
                case "Fisch":
                recipe.kinds = Kind(rawValue: 1 << 2)
                case "Fleisch":
                recipe.kinds = Kind(rawValue: 1 << 3)
                default: break
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
