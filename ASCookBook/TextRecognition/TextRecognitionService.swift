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
    
    func extractRecipe(from imageUrl: URL) async throws -> RecipeResponse {
        let url = URL(string: "https://api.openai.com/v1/responses")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let message = """
            Du bist ein hilfreicher Assistent, der Rezepte aus Fotos extrahiert. Die folgende URL verweist auf ein Foto, das ein Rezept enthält. Das Rezept enthält Zutaten und die Anleitung zur Zubereitung einer Mahlzeit und evtl. zusätzlichen Text. Die Zutaten und die Anleitungen können vermischt sein. Bitte extrahiere das eigentliche Rezept aus dem Text. Gib ihm einen Titel und Überschriften für Zutaten und Zubereitungen. Wenn Inhalte sich direkt auf das Rezept beziehen, nimm sie auf. Wichtig sind z.B. die Anzahl der Portionen. Auch Überschriften in den Zutaten oder der Zubereitungsanweisung sollen erhalten bleiben. Verwende nur die Inhalte des Textes. Füge nichts hinzu, was nicht im Text steht. Sollten Worte getrennt sein, füge sie zusammen. 
            Wichtig: Unabhängig davon, in welcher Sprache der Text verfasst ist, gib das Rezept (Zutaten, Zubereitung und Portionen) immer in Deutscher Sprache aus. 
            Ist die URL nicht erreichbar, gib ein leeres Rezept mit dem Titel "URL nicht erreichbar" zurück. Ist an der URL kein Foto vorhanden, gib ein leeres Rezept mit dem Titel "Kein Foto vorhanden" zurück. 
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
//                    "description": "Step-by-step cooking instructions"
                    "description": "Cooking instructions"
                ],
                "servings": [
                    "type": "string",
                    "description": "Number of servings the recipe makes"
                ]
            ],
            "required": ["title", "ingredients", "instructions", "servings"],
            "additionalProperties": false
        ]

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "input": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "input_text",
                            "text": message
                        ],
                        [
                            "type": "input_image",
                            "image_url": imageUrl.absoluteString
                        ]
                    ]
                ]
            ],
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
        if let http = resp as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            print("Status: \(http.statusCode)")
            print("Body:", String(data: data, encoding: .utf8) ?? "<non-utf8>")
            throw NSError(domain: "OpenAIService", code: 1, userInfo: ["response": resp])
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
