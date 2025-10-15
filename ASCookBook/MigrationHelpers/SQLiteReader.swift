//
//  SQLiteReader.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 24.09.25.
//
import Foundation
import SQLite3

func readRecipes(dbPath: String) -> [(Int, String, String, String, String, Int, Int, Data?, String?, Int?, Int?, Int?)] {
    var db: OpaquePointer?
    var results: [(Int, String, String, String, String, Int, Int, Data?, String?, Int?, Int?, Int?)] = []
    if sqlite3_open(dbPath, &db) == SQLITE_OK {
        let query = """
            SELECT r.Z_PK, r.ZNAME, r.ZORT, r.ZPORTIONEN, r.ZZUTATEN, r.ZJAHRESZEIT, r.ZKATEGORIE, 
                   p.ZREZEPTPHOTO, r.ZART, r.ZAMUSEGUEULE, r.ZSNACK, r.ZSUPPE 
            FROM ZREZEPT r 
            LEFT JOIN ZREZEPTPHOTO p ON r.ZREZEPTPHOTO = p.Z_PK
        """
        var stmt: OpaquePointer?
        if sqlite3_prepare(db, query, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(stmt, 0))
                let name = String(cString: sqlite3_column_text(stmt, 1))
                let place: String
                if sqlite3_column_type(stmt, 2) != SQLITE_NULL {
                    place = String(cString: sqlite3_column_text(stmt, 2))
                } else {
                    place = ""
                }
                let portions = String(cString: sqlite3_column_text(stmt, 3))
                let ingredients = String(cString: sqlite3_column_text(stmt, 4))
                let seasonId = Int(sqlite3_column_int(stmt, 5))
                let categoryId = Int(sqlite3_column_int(stmt, 6))
                
                // Get photo data from BLOB
                let photoData: Data?
                if sqlite3_column_type(stmt, 7) != SQLITE_NULL {
                    if let blobPointer = sqlite3_column_blob(stmt, 7) {
                        let blobSize = Int(sqlite3_column_bytes(stmt, 7))
                        photoData = Data(bytes: blobPointer, count: blobSize)
                    } else {
                        photoData = nil
                    }
                } else {
                    photoData = nil
                }
                
                let kindString: String?
                if sqlite3_column_type(stmt, 8) != SQLITE_NULL {
                    kindString = String(cString: sqlite3_column_text(stmt, 8))
                } else {
                    kindString = nil
                }
                let amusegueule = Int(sqlite3_column_int(stmt, 9))
                let snack = Int(sqlite3_column_int(stmt, 10))
                let soup = Int(sqlite3_column_int(stmt, 11))
                results.append((id, name, place, portions, ingredients, seasonId, categoryId, photoData, kindString, amusegueule, snack, soup))
            }
        }
        sqlite3_finalize(stmt)
    }
    sqlite3_close(db)
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


