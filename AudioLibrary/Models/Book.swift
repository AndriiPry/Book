//
//  Book.swift
//  AudioLibrary
//
//  Created by Oleksii on 07.08.2025.
//

import Foundation


struct Book: Identifiable, Codable, Equatable {
    static func == (lhs: Book, rhs: Book) -> Bool {
        return lhs.id == rhs.id &&
               lhs.pages == rhs.pages &&
               lhs.metadata == rhs.metadata &&
               lhs.bookType == rhs.bookType &&
               lhs.coverImagePath == rhs.coverImagePath
    }
    
    let id: UUID
    let pages: [Page]
    let metadata: BookMetadata
    let bookType: BookType
    let coverImagePath: String?
    
    init(pages: [Page], metadata: BookMetadata, bookType: BookType = .default, coverImagePath: String? = nil) {
        if let id = metadata.id {
            self.id = id
        } else {
            self.id = UUID()
        }
        self.pages = pages
        self.metadata = metadata
        self.bookType = bookType
        self.coverImagePath = coverImagePath
    }
}

enum BookType: String, Codable {
    case `default` = "default"
    case downloaded = "downloaded"
}
