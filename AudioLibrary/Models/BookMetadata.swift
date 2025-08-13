//
//  BookMetadata.swift
//  AudioLibrary
//
//  Created by Oleksii on 07.08.2025.
//

import Foundation

struct BookMetadata: Codable, Equatable {
    let id: UUID?
    let name: String
    let author: String
    let ageGroup: String
    let language: String
    let pageCount: Int
    let tags: [String]
    let bookType: String
}
