//
//  Special.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 27.09.25.
//
import SwiftData

struct Special: OptionSet, Codable {
    let rawValue: Int
    
    static let amuseGuele = Special(rawValue: 1 << 0)
    static let snack = Special(rawValue: 1 << 1)
    static let soup = Special(rawValue: 1 << 2)
    
    static let allCases: [Special] = [.amuseGuele, .snack, .soup]
    
    var displayName: String {
        switch self {
        case .amuseGuele: return "Amuse Gueule"
        case .snack: return "Snack"
        case .soup: return "Suppe"
        default: return "Unknown"
        }
    }
    
    var title: String {
        Special.allCases.filter { self.contains($0) }.map { $0.displayName }.joined(separator: ", ")
    }
    
}
