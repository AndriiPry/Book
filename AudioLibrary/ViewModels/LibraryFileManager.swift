//
//  LibraryFileManager.swift
//  AudioLibrary
//
//  Created by Oleksii on 07.08.2025.
//

import Foundation
import UIKit

class LibraryFileManager {
    static let shared = LibraryFileManager()
    
    private let fileManager = FileManager.default
    private let resourcePath = Bundle.main.resourcePath ?? ""
    
    private enum Constants {
        static let booksPath = "AppResources/Books"
        static let defaultBooksPath = "AppResources/Books/Default"
        static let downloadedBooksPath = "AppResources/Books/Downloaded" // will download downloaded to DOCUMENTS. Placeholder
        static let coverImageName = "coverImage.jpg"
        static let metadataFileName = "metadata.json"
        static let pagesDirectoryName = "Pages"
        static let textFileName = "text.txt"
        static let audioFileName = "audio.mp3"
        static let backgroundImageName = "bgImage.jpg"
    }
    
    private init() {}
    
    // MARK: - Book Loading Methods
    
    func getAllBooks() -> [Book] {
        return getDefaultBooks() + getDownloadedBooks()
    }
    
    func getDefaultBooks() -> [Book] {
        let defaultBooksPath = (resourcePath as NSString).appendingPathComponent(Constants.defaultBooksPath)
        return loadBooksFromDirectory(defaultBooksPath, type: .default)
    }
    
    func getDownloadedBooks() -> [Book] { // PLACEHOLDER
        return []
    }
    
    func getBook(named bookName: String) -> Book? {
        let normalizedName = convertToDirectoryName(bookName)
        return getAllBooks().first { convertToDirectoryName($0.metadata.name) == normalizedName }
    }
    
    // MARK: - Private Helper Methods
    
    private func loadBooksFromDirectory(_ directoryPath: String, type: BookType) -> [Book] {
        guard let bookDirectories = try? fileManager.contentsOfDirectory(atPath: directoryPath) else {
            return []
        }
        //print(bookDirectories)
        return bookDirectories.compactMap { bookDirectory -> Book? in
            let bookPath = (directoryPath as NSString).appendingPathComponent(bookDirectory)
            //let bookPathContents = try? fileManager.contentsOfDirectory(atPath: bookPath)
            //print(bookPathContents as Any)
            let metadataPath = (bookPath as NSString).appendingPathComponent(Constants.metadataFileName)
            
            guard let metadataData = try? Data(contentsOf: URL(fileURLWithPath: metadataPath)) else {
                print("Could not load metadata for \(bookDirectory)")
                return nil
            }
            var metadata: BookMetadata
            do {
                metadata = try JSONDecoder().decode(BookMetadata.self, from: metadataData)
            }
            catch {
                print("Could not decode metadata for \(bookDirectory)")
                print(error)
                return nil
            }
            
            let pages = loadPages(fromBookPath: bookPath, pageCount: metadata.pageCount)
            //print(pages)
            let coverImagePath = (bookPath as NSString).appendingPathComponent(Constants.coverImageName)
            return Book(pages: pages, metadata: metadata, coverImagePath: coverImagePath)
        }
    }
    
    private func loadPages(fromBookPath bookPath: String, pageCount: Int) -> [Page] {
        var pages: [Page] = []
        let pagesPath = (bookPath as NSString).appendingPathComponent(Constants.pagesDirectoryName)
        
        for pageNumber in 1...pageCount {
            let pagePath = (pagesPath as NSString).appendingPathComponent("\(pageNumber)")
            let textPath = (pagePath as NSString).appendingPathComponent(Constants.textFileName)
            
            guard let text = try? String(contentsOfFile: textPath, encoding: .utf8) else {
                continue
            }
            let pageImagePath = (pagePath as NSString).appendingPathComponent(Constants.backgroundImageName)
            let audioPath = (pagePath as NSString).appendingPathComponent(Constants.audioFileName)
            pages.append(Page(pageNumber: pageNumber, text: text, bgImagePath: pageImagePath, audioPath: audioPath))
        }
        
        return pages
    }
    
    private func getBookPath(for book: Book) -> String {
        let typePath = book.bookType == .default ? Constants.defaultBooksPath : Constants.downloadedBooksPath
        let dirName = convertToDirectoryName(book.metadata.name)
        return (typePath as NSString).appendingPathComponent(dirName)
    }
    
    private func getPagePath(for book: Book, pageNumber: Int) -> String {
        let bookPath = getBookPath(for: book)
        let pagesPath = (bookPath as NSString).appendingPathComponent(Constants.pagesDirectoryName)
        return (pagesPath as NSString).appendingPathComponent("\(pageNumber)")
    }
    
    private func convertToDirectoryName(_ name: String) -> String {
        return name.replacingOccurrences(of: " ", with: "_")
    }
}
