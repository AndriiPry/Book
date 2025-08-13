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
    
    // will download downloaded to DOCUMENTS
    
    private enum Constants {
        static let booksPath = "AppResources/Books"
        static let defaultBooksPath = "AppResources/Books/Default"
        static let downloadedBooksPath = "AppResources/Books/Downloaded" // MARK: PLACEHOLDER
        static let coverImageName = "coverImage.jpg"
        static let metadataFileName = "metadata.json"
        static let pagesDirectoryName = "Pages"
        static let textFileName = "text.txt"
        static let audioFileName = "audio.mp3"
        static let backgroundImageName = "bgImage.jpg"
        static let langDirName = "lang"
    }
    
    private init() {}
    
    // MARK: - Book Loading Methods
    
    func getAllBooks(_ lang: String) -> [Book] {
        return getDefaultBooks(lang) + getDownloadedBooks(lang)
    }
    
    func getDefaultBooks(_ lang: String) -> [Book] {
        let defaultBooksPath = (resourcePath as NSString).appendingPathComponent(Constants.defaultBooksPath)
        return loadBooksFromDirectory(defaultBooksPath, type: .default, lang)
    }
    
    func getDownloadedBooks(_ lang: String) -> [Book] { // PLACEHOLDER
        return []
    }
    
    func getBook(named bookName: String) -> Book? {
        let normalizedName = convertToDirectoryName(bookName)
        return getAllBooks("en").first { convertToDirectoryName($0.metadata.name["en"] ?? "") == normalizedName }
    }
    
    // MARK: - Private Helper Methods
    
    private func loadBooksFromDirectory(_ directoryPath: String, type: BookType, _ lang: String) -> [Book] {
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
            
            let pages = loadPages(fromBookPath: bookPath, pageCount: metadata.pageCount, lang)
            //print(pages)
            let coverImagePath = (bookPath as NSString).appendingPathComponent(Constants.coverImageName)
            return Book(pages: pages, metadata: metadata, coverImagePath: coverImagePath)
        }
    }
    
    private func loadPages(fromBookPath bookPath: String, pageCount: Int, _ lang: String) -> [Page] {
        var pages: [Page] = []
        let pagesPath = (bookPath as NSString).appendingPathComponent(Constants.pagesDirectoryName)
        
        print("📚 Starting to load \(pageCount) pages from book path: \(bookPath)")
        print("   Pages directory: \(pagesPath)")
        
        for pageNumber in 1...pageCount {
            print("\n🔹 Loading page \(pageNumber)...")
            
            let pagePath = (pagesPath as NSString).appendingPathComponent("\(pageNumber)")
            print("   Page directory: \(pagePath)")
            
            let pageImagePath = (pagePath as NSString).appendingPathComponent(Constants.backgroundImageName)
            print("   Background image path: \(pageImagePath)")
            
            let langsPath = (pagePath as NSString).appendingPathComponent(Constants.langDirName)
            let langPath = (langsPath as NSString).appendingPathComponent(lang)
            print("   Language directory: \(langPath)")
            
            let textPath = (langPath as NSString).appendingPathComponent(Constants.textFileName)
            print("   Text file path: \(textPath)")
            
            guard let text = try? String(contentsOfFile: textPath, encoding: .utf8) else {
                print("   ⚠️ Could not load text for page \(pageNumber) — skipping.")
                continue
            }
            print("   ✅ Loaded text for page \(pageNumber) (\(text.count) characters).")
            
            let audioPath = (langPath as NSString).appendingPathComponent(Constants.audioFileName)
            print("   Audio file path: \(audioPath)")
            
            pages.append(Page(
                pageNumber: pageNumber,
                text: text,
                bgImagePath: pageImagePath,
                audioPath: audioPath
            ))
            print("   ✅ Page \(pageNumber) added to the list.")
        }
        
        print("\n📖 Finished loading pages. Total loaded: \(pages.count)/\(pageCount)")
        return pages
    }

    
    private func getBookPath(for book: Book) -> String {
        let typePath = book.bookType == .default ? Constants.defaultBooksPath : Constants.downloadedBooksPath
        let dirName = convertToDirectoryName(book.metadata.name["en"] ?? "")
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
