//
//  TextRecognition.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 20.10.25.
//
import UIKit
import Vision

class TextRecognition {
    func extractText() {
        guard let cgImage = UIImage(named: "snapshot.jpeg")?.cgImage else {
            print("File not found")
                return
        }

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
        print(joined)
    }
}
