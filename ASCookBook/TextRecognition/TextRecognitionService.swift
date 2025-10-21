//
//  Untitled.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 19.10.25.
//
import Foundation
import SwiftUI
import Vision

class TextRecognitionService {
    private let apiKey = Constants.openAIKey
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }


    func extractRecipe(from imageData: Data) async throws -> RecipeResponse {
        guard let uiImage = UIImage(data: imageData) else { 
            throw NSError(domain: "TextRecognitionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
        }
        guard let cgImage = uiImage.cgImage else { 
            throw NSError(domain: "TextRecognitionService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not create CGImage from UIImage"])
        }

        // Create a new image-request handler.
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)

        // Use async/await for Vision framework
        return try await withCheckedThrowingContinuation { continuation in
            // Create a new request to recognize text with completion handler
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: NSError(domain: "TextRecognitionService", code: 3, userInfo: [NSLocalizedDescriptionKey: "No text observations found"]))
                    return
                }
                
                let recognizedStrings = observations.compactMap { observation in
                    return observation.topCandidates(1).first?.string
                }
                
                let joined = recognizedStrings.joined(separator: "\n")
                
                Task {
                    do {
                        let recipeResponse = try await self.processRecipeText(joined)
                        continuation.resume(returning: recipeResponse)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Processes the recognized text and sends it to OpenAI for recipe extraction.
    /// Returns a RecipeResponse or throws.
    private func processRecipeText(_ recipeString: String) async throws -> RecipeResponse {
        // Example endpoint — adjust model and URL if using a multimodal / vision model
//        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        let url = URL(string: "https://api.openai.com/v1/responses")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        //Please extract the recipe in German language in JSON format with keys: \"title\", \"ingredients\", \"instructions\".
        let message = """
            You are a helpful assistant that extracts recipe details from a text.
            The following text is extracted from a recipe book. It contains ingredients and instructions for preparing a dish and may be some more text. The ingredients and instructions may be mixed up. 
            Please extract the recipe in German language. Give it a title and headlines for "Zutaten" and "Zubereitung".
            Only use the terms from the text; do not add any new ones. All content directly related to the preparation, e.g., the number of servings or headings in the ingredient list, should be retained. Please combine words that are separated into one word. Here is the text:
            \(recipeString)
            """
        
        let jsonSchema: [String: Any] = [
            "type": "object",
            "properties": [
                "title": [
                    "type": "string",
                    "description": "The title of the recipe"
                ],
                "ingredients": [
                    "type": "array",
                    "items": [
                        "type": "string"
                    ],
                    "description": "List of ingredients for the recipe"
                ],
                "instructions": [
                    "type": "string",
                    "description": "Step-by-step cooking instructions"
                ]
            ],
            "required": ["title", "ingredients", "instructions"],
            "additionalProperties": false
        ]
        
        let body: [String: Any] = [
            "model": "gpt-4o-mini", // adjust to correct model that accepts vision/image input
            "input": message,
            "text": [
                "format": [
                    "type": "json_schema",
                    "name": "recipe_response",
                    "schema": jsonSchema,
                    "strict": true
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        
        let (data, resp) = try await session.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            print("Error-----> \(resp)")
            throw NSError(domain: "OpenAIService", code: 1, userInfo: [ "response": resp ])
        }
        
         // Decode the completion response for the new API structure
         struct APIResponse: Decodable {
             struct Output: Decodable {
                 let id: String
                 let type: String
                 let status: String
                 let content: [Content]
                 let role: String
             }
             
             struct Content: Decodable {
                 let type: String
                 let annotations: [String]
                 let logprobs: [String]
                 let text: String
             }
             
             let output: [Output]
         }
         
         let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
         guard let firstOutput = apiResponse.output.first,
               let firstContent = firstOutput.content.first else {
             throw NSError(domain: "OpenAIService", code: 2, userInfo: [ "reason": "No content returned" ])
         }
         
         // The text content contains the JSON string with our recipe structure
         guard let jsonData = firstContent.text.data(using: .utf8) else {
             throw NSError(domain: "OpenAIService", code: 3, userInfo: [ "reason": "Cannot convert content to data" ])
         }
         
        return try JSONDecoder().decode(RecipeResponse.self, from: jsonData)
    }
}
