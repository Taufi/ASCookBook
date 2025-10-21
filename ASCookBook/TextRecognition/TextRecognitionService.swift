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
    
    var recipeResponse: RecipeResponse? = nil
    
    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Completion handler for text recognition requests.
    /// Processes the recognized text observations and prints the strings.
    func recognizeTextHandler(request: VNRequest, error: Error?) {
        guard let observations =
                request.results as? [VNRecognizedTextObservation] else {
            return
        }
        let recognizedStrings = observations.compactMap { observation in
            // Return the string of the top VNRecognizedText instance.
            return observation.topCandidates(1).first?.string
        }
        
        // Process the recognized strings.
        let joined = recognizedStrings.joined(separator: "\n")
        
        Task { [weak self] in
            try? await self?.extractRecipe(from: joined)
        }
    }

    func extractRecipe(from imageData: Data) {
        guard let uiImage = UIImage(data: imageData) else { return }
        guard let cgImage = uiImage.cgImage else { return }

        // Create a new image-request handler.
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)

        // Create a new request to recognize text.
        let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)

        do {
            // Perform the text-recognition request.
            try requestHandler.perform([request])
        } catch {
            print("Unable to perform the requests: \(error).")
        }
    }
    
    /// Sends the image data plus a prompt asking to extract recipe info.
    /// Returns a RecipeResponse or throws.
    //func extractRecipe(from imageData: Data) async throws -> RecipeResponse {
    func extractRecipe(from recipeString: String) async throws {
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
         
            recipeResponse = try JSONDecoder().decode(RecipeResponse.self, from: jsonData)
         
    }
}
