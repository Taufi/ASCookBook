//
//  SQLiteReader.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 24.09.25.
//
import Foundation
import SQLite3

func readRecipes(dbPath: String) -> [(Int, String, String?, String, String, Int, Int, Int?)] {
    var db: OpaquePointer?
    var results: [(Int, String, String?, String, String, Int, Int, Int?)] = []
    if sqlite3_open(dbPath, &db) == SQLITE_OK {
        let query = "SELECT Z_PK, ZNAME, ZORT, ZPORTIONEN, ZZUTATEN, ZJAHRESZEIT, ZKATEGORIE, ZREZEPTPHOTO FROM ZREZEPT"
        var stmt: OpaquePointer?
        if sqlite3_prepare(db, query, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(stmt, 0))
                let name = String(cString: sqlite3_column_text(stmt, 1))
                let place: String?
                if sqlite3_column_type(stmt, 2) != SQLITE_NULL {
                    place = String(cString: sqlite3_column_text(stmt, 2))
                } else {
                    place = nil
                }
                let portions = String(cString: sqlite3_column_text(stmt, 3))
                let ingredients = String(cString: sqlite3_column_text(stmt, 4))
                let seasonId = Int(sqlite3_column_int(stmt, 5))
                let categoryId = Int(sqlite3_column_int(stmt, 6))
                let photoId = Int(sqlite3_column_int(stmt, 7))
                results.append((id, name, place, portions, ingredients, seasonId, categoryId, photoId))
            }
        }
    }
    return results
}

func readSeasons(dbPath: String) -> [(Int,String)] {
    var db: OpaquePointer?
    var results: [(Int, String)] = []
    if sqlite3_open(dbPath, &db) == SQLITE_OK {
        let query = "SELECT Z_PK, ZJAHRESZEIT FROM ZJAHRESZEIT"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(stmt, 0))
                let title = String(cString: sqlite3_column_text(stmt, 1))
                results.append((id, title))
            }
        }
        sqlite3_finalize(stmt)
    }
    sqlite3_close(db)
    return results
}

func readCategories(dbPath: String) -> [(Int,String)] {
    var db: OpaquePointer?
    var results: [(Int, String)] = []
    if sqlite3_open(dbPath, &db) == SQLITE_OK {
        let query = "SELECT Z_PK, ZKATEGORIE FROM ZKATEGORIE"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(stmt, 0))
                let title = String(cString: sqlite3_column_text(stmt, 1))
                results.append((id, title))
            }
        }
        sqlite3_finalize(stmt)
    }
    sqlite3_close(db)
    return results
}

func getWritableDatabaseURL() -> URL? {
    let fileManager = FileManager.default

    guard let bundleDbURL = Bundle.main.url(forResource: "CookBook", withExtension: "sqlite") else {
        return nil
    }

    let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let writableDbURL = docsURL.appendingPathComponent("CookBook.sqlite")

    // Copy if needed
    if !fileManager.fileExists(atPath: writableDbURL.path) {
        do {
            try fileManager.copyItem(at: bundleDbURL, to: writableDbURL)
        } catch {
            print("Failed to copy DB: \(error)")
            return nil
        }
    }
    return writableDbURL
}
