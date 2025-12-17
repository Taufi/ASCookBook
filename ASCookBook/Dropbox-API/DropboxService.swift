//
//  DropboxService.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 14.12.25.
//
import Foundation
import UIKit

class DropboxService {
    private let accessToken = Constants.dropboxAccessToken
    
    func uploadAndGetTemporaryLink(image: UIImage, path: String = "/recipe.jpg") async throws -> URL {
        let uploadURL = URL(string: "https://content.dropboxapi.com/2/files/upload")!
        
        var uploadRequest = URLRequest(url: uploadURL)
        uploadRequest.httpMethod = "POST"
        uploadRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        uploadRequest.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        
        let args: [String: Any] = [
            "path": path,
            "mode": "overwrite",
            "autorename": false,
            "mute": true
        ]
        
        let argsData = try JSONSerialization.data(withJSONObject: args)
        let argsString = String(data: argsData, encoding: .utf8)!
        uploadRequest.setValue(argsString, forHTTPHeaderField: "Dropbox-API-Arg")
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw URLError(.badServerResponse)
        }
        
        print("Request headers:", uploadRequest.allHTTPHeaderFields!)
        print("Dropbox-API-Arg:", argsString)
        print("Path being used:", path)
        
        let (responseData, uploadResponse) = try await URLSession.shared.upload(for: uploadRequest, from: imageData)
        guard let httpResponse = uploadResponse as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            print("Status Code:", httpResponse.statusCode)
            if let errorString = String(data: responseData, encoding: .utf8) {
                print("Error response body:", errorString)
            }
            throw URLError(.cannotCreateFile)
        }
        
        let tempLinkURL = URL(string: "https://api.dropboxapi.com/2/files/get_temporary_link")!
        var linkRequest = URLRequest(url: tempLinkURL)
        linkRequest.httpMethod = "POST"
        linkRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        linkRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let linkBody = ["path": path]
        linkRequest.httpBody = try? JSONSerialization.data(withJSONObject: linkBody)
        
        let (data, resp) = try await URLSession.shared.data(for: linkRequest)
        
        guard let httpResponse = resp as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            print("Status Code:", httpResponse.statusCode)
            if let errorString = String(data: data, encoding: .utf8) {
                print("Error response body:", errorString)
            }
            throw URLError(.badServerResponse)
        }
        
        struct TempLinkResponse: Decodable {
            let link: String
        }
        
        let decoded = try JSONDecoder().decode(TempLinkResponse.self, from: data)
        guard let url = URL(string: decoded.link) else {
            throw URLError(.badURL)
        }
        
        return url
    }
                                   
}
