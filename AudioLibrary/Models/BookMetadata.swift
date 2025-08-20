//
//  BookMetadata.swift
//  AudioLibrary
//
//  Created by Oleksii on 07.08.2025.
//

import Foundation

//{
//  "id": null,
//  "name": {
//    "en": "The Rabbit and the Computer",
//    "ua": "Кролик та комп'ютер"
//  },
//  "author": {
//    "en": "Story Author",
//    "ua": "Автор історії"
//  },
//  "ageGroup": "3-5",
//  "pageCount": 3,
//  "createdDate": "2025-01-15T00:00:00Z",
//  "tags": ["animals", "friendship", "adventure"],
//  "bookType": "default"
//}

struct BookMetadata: Codable, Equatable {
    let id: UUID?
    let name: [String: String]
    let author: [String: String]
    let ageGroup: String
    let pageCount: Int
    let tags: [String]
    let bookType: String
}
