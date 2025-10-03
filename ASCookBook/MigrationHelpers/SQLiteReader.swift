//
//  SQLiteReader.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 24.09.25.
//
import Foundation
import SQLite3

func readRecipes(dbPath: String) -> [(Int, String, String?, String, String, Int, Int, Int?, String?, Int?, Int?, Int?)] {
    var db: OpaquePointer?
    var results: [(Int, String, String?, String, String, Int, Int, Int?, String?, Int?, Int?, Int?)] = []
    if sqlite3_open(dbPath, &db) == SQLITE_OK {
        let query = "SELECT Z_PK, ZNAME, ZORT, ZPORTIONEN, ZZUTATEN, ZJAHRESZEIT, ZKATEGORIE, ZREZEPTPHOTO, ZART, ZAMUSEGUEULE, ZSNACK, ZSUPPE FROM ZREZEPT"
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
                let kindString: String?
                if sqlite3_column_type(stmt, 8) != SQLITE_NULL {
                    kindString = String(cString: sqlite3_column_text(stmt, 8))
                } else {
                    kindString = nil
                }
                let amusegueule = Int(sqlite3_column_int(stmt, 9))
                let snack = Int(sqlite3_column_int(stmt, 10))
                let soup = Int(sqlite3_column_int(stmt, 11))
                results.append((id, name, place, portions, ingredients, seasonId, categoryId, photoId, kindString, amusegueule, snack, soup))
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

func readImages(dbPath: String) {
    var db: OpaquePointer?
    if sqlite3_open(dbPath, &db) == SQLITE_OK {
        let query = "SELECT Z_PK, ZREZEPTPHOTO from ZREZEPTPHOTO WHERE ZREZEPT IS NOT NULL;"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                // Get ZREZEPT
                let rezeptValue = sqlite3_column_type(stmt, 0) != SQLITE_NULL ? sqlite3_column_int(stmt, 0) : -1
                // Get the image blob
                if let blobPointer = sqlite3_column_blob(stmt, 1) {
                    let blobSize = Int(sqlite3_column_bytes(stmt, 1))
                    let blobData = Data(bytes: blobPointer, count: blobSize)
                    // Create file name
                    let fileName: String
                    if rezeptValue >= 0 {
                        fileName = String(format: "image%d.jpg", rezeptValue)
                    } else {
                        // Fallback if ZREZEPT is null
                        fileName = UUID().uuidString + ".jpg"
                    }
                    let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                    let imageURL = appSupportURL.appendingPathComponent(fileName)
                    do {
                        try blobData.write(to: imageURL)
                        print("Saved: \(imageURL.path)")
                    } catch {
                        print("Error saving \(fileName): \(error)")
                    }
                }
            }
            sqlite3_finalize(stmt)
        } else {
            print("Failed to prepare statement")
        }
    }
    sqlite3_close(db)
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
