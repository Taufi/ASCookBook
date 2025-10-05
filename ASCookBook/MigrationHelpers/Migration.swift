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
        let recipe = Recipe(name: name, place: place, ingredients: ingredients, portions: portions, season: season, category: category, photoId: photoId, kinds: [], specials: []) 
        
        if kindString != nil {
            switch kindString! {
                case "Vegan":
                    recipe.kinds = .vegan
                case "Vegetarisch":
                    recipe.kinds = .vegetarian
                case "Fisch":
                    recipe.kinds = .fish
                case "Fleisch":
                    recipe.kinds = .meat
                default: break
            }
        }
        

        if amusegueule == 1 {
            recipe.specials.insert(.amuseGuele)
        }
        if snack == 1 {
            recipe.specials.insert(.snack)
        }
        if soup == 1 {
            recipe.specials.insert(.soup)
        }
        context.insert(recipe)
    }
    
    readImages(dbPath: dbPath)
    
}
