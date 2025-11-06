//
//  Constants.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 06.11.25.
//


import Foundation

enum Constants {
  static var openAIKey: String {
    ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
  }
}
