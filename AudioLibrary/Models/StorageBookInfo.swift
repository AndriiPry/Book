//
//  StorageBookInfo.swift
//  AudioLibrary
//
//  Created by Oleksii on 28.08.2025.
//
import Foundation

struct StorageBookInfo: Codable {
    let id: UUID
    let coverUrlString: String
    let metadataUrlString: String
}

struct BookPagesResponse: Codable {
    let success: Bool
    let bookId: String
    let pageCount: Int
    let languages: [String]
    let pages: [PageUrls]
    let error: String?
}

struct PageUrls: Codable {
    let pageNumber: Int
    let bgImageUrlString: String
    let languages: [String: LanguageUrls]
}

struct LanguageUrls: Codable {
    let audioUrlString: String
    let textUrlString: String
}
