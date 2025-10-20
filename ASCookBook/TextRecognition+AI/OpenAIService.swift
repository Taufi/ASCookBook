//
//  Untitled.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 19.10.25.
//
import Foundation
import SwiftUI

class OpenAIService {
    private let apiKey = Constants.openAIKey
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    /// Sends the image data plus a prompt asking to extract recipe info.
    /// Returns a RecipeResponse or throws.
    func extractRecipe(from imageData: Data) async throws -> RecipeResponse {
        // Example endpoint — adjust model and URL if using a multimodal / vision model
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare the multipart or base64 image payload depending on model spec.
        // For simplicity we’ll encode image in base64 and embed in the prompt.
        let base64Image = imageData.base64EncodedString()
        
        let systemMessage = [
            "role": "system",
            "content": "You are a helpful assistant that extracts recipe details from a text."
        ]
        let userMessage = [
            "role": "user",
            "content": "Here is an image of a dish. Please extract the recipe in German language in JSON format with keys: \"title\", \"ingredients\" (array), \"instructions\".\n\nImage (base64): \(base64Image)"
        ]
        
        let body: [String: Any] = [
            "model": "gpt-4o-mini", // adjust to correct model that accepts vision/image input
            "messages": [systemMessage, userMessage],
            "max_tokens": 300,
            "temperature": 0.2
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        
        let (data, resp) = try await session.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "OpenAIService", code: 1, userInfo: [ "response": resp ])
        }
        
        // Decode the completion response. The exact shape depends on API. For example:
        struct ChatCompletionResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let role: String
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }
        
        let completion = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let content = completion.choices.first?.message.content else {
            throw NSError(domain: "OpenAIService", code: 2, userInfo: [ "reason": "No content returned" ])
        }
        
        // The content is expected to be a JSON string with our structure.
        guard let jsonData = content.data(using: .utf8) else {
            throw NSError(domain: "OpenAIService", code: 3, userInfo: [ "reason": "Cannot convert content to data" ])
        }
        
        let recipe = try JSONDecoder().decode(RecipeResponse.self, from: jsonData)
        return recipe
    }
}
