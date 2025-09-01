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
    private let documentsPath =  try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).path
    
    private var isInitialized = false
    private var initializationTask: Task<Void, Never>?
    
    //private var baseAPIurlString = "https://us-central1-audio-library-services.cloudfunctions.net/api"
    private var baseAPIurlString = "https://us-central1-tomo-books.cloudfunctions.net/api"
    
    private enum Constants {
        static let booksPath = "AppResources/Books"
        static let defaultBooksPath = "AppResources/Books/Default"
        static let downloadedBooksPath = "AppResources/Books/Downloaded"
        static let coverImageName = "coverImage.jpg"
        static let metadataFileName = "metadata.json"
        static let pagesDirectoryName = "Pages"
        static let textFileName = "text.txt"
        static let audioFileName = "audio.mp3"
        static let backgroundImageName = "bgImage.jpg"
        static let langDirName = "lang"
    }
    
    public var downloadedDirectoryExists: Bool {
        var isDir: ObjCBool = false
        let exists = fileManager.fileExists(
            atPath: (documentsPath as NSString).appendingPathComponent(Constants.downloadedBooksPath),
            isDirectory: &isDir
        )
        return exists && isDir.boolValue
    }
    
    public var downloadedDirectoryContentCount: Int {
        var isDir: ObjCBool = false
        let exists = fileManager.fileExists(
            atPath: (documentsPath as NSString).appendingPathComponent(Constants.downloadedBooksPath),
            isDirectory: &isDir
        )
        guard exists && isDir.boolValue else { return 0 }
        
        do {
            let directoryPath = (documentsPath as NSString).appendingPathComponent(Constants.downloadedBooksPath)
            let contents = try fileManager.contentsOfDirectory(atPath: directoryPath)
            return contents.count
        } catch {
            print("Error reading directory contents: \(error)")
            return 0
        }
    }
    
    private init() {}
    
    // MARK: - Book Loading Methods
    
    func getAllBooks(_ lang: String) -> [Book] {
        return getDefaultBooks(lang) + getDownloadedBooks(lang)
    }
    
    func getDefaultBooks(_ lang: String) -> [Book] {
        print("getting default books")
        let defaultBooksPath = (resourcePath as NSString).appendingPathComponent(Constants.defaultBooksPath)
        return loadBooksFromDirectory(defaultBooksPath, type: .default, lang)
    }
    // MARK: TESTING
    func getDownloadedBooks(_ lang: String) -> [Book] {
        print("getting downloaded books")
        let downloadedBooksPath = (documentsPath as NSString).appendingPathComponent(Constants.downloadedBooksPath)
        return loadBooksFromDirectory(downloadedBooksPath, type: .downloaded, lang)
    }
    
    func ensureInitialized() async {
        guard !isInitialized else { return }
        
        // If initialization is already in progress, wait for it
        if let existingTask = initializationTask {
            await existingTask.value
            return
        }
        
        // Start initialization
        initializationTask = Task {
            await initializeDownloadedDir()
            await MainActor.run {
                self.isInitialized = true
                self.initializationTask = nil
            }
        }
        
        await initializationTask?.value
    }
    
    func initializeDownloadedDir() async {
        if downloadedDirectoryExists {
            print("checking and downloading new book covers")
            if downloadedDirectoryContentCount > 0 {
                await checkAndDownloadNewBookCovers()
            } else {
                await downloadBookCoversFromStorage()
            }
        } else {
            print("creating downloaded directory")
            createDownloadedDir()
            print("download book covers from storage")
            await downloadBookCoversFromStorage()
        }
    }
    
    func createDownloadedDir() {
        let booksDirectory = (documentsPath as NSString).appendingPathComponent(Constants.downloadedBooksPath)
        let booksDirUrl = URL(filePath: booksDirectory)
        do {
            try fileManager.createDirectory(at: booksDirUrl, withIntermediateDirectories: true)
        } catch {
            print("could not create directory: \(error)")
            return
        }
    }
    
    func getDownloadedBookIds() -> [UUID] {
        let downloadedBooksPath = (documentsPath as NSString).appendingPathComponent(Constants.downloadedBooksPath)
        
        guard fileManager.fileExists(atPath: downloadedBooksPath) else {
            print("Downloaded books directory does not exist")
            return []
        }
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: downloadedBooksPath)
            let bookIds = contents.compactMap { folderName -> UUID? in
                return UUID(uuidString: folderName)
            }
            print("Found \(bookIds.count) downloaded book IDs")
            return bookIds
        } catch {
            print("Error reading downloaded books directory: \(error)")
            return []
        }
    }

    func checkAndDownloadNewBookCovers() async {
        // Get all book IDs from the server
        guard let url = URL(string: baseAPIurlString + "/api/bookIds") else {
            print("Invalid API URL for bookIds")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        
        print("Fetching all book IDs from server...")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Debug: Print HTTP status code
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
            }
            
            // Debug: Print raw response as string
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw response: \(responseString)")
            }
            
            let decodedResponse = try JSONDecoder().decode(BookIdsResponse.self, from: data)
            
            guard decodedResponse.success else {
                print("Server returned error when fetching book IDs")
                return
            }
            
            // Convert server book IDs to UUID array
            let serverBookIds = decodedResponse.bookIds.compactMap { UUID(uuidString: $0) }
            print("Server has \(serverBookIds.count) book IDs")
            
            // Get locally downloaded book IDs
            let localBookIds = getDownloadedBookIds()
            print("Local has \(localBookIds.count) book IDs")
            
            // Find new book IDs (present on server but not locally)
            let newBookIds = serverBookIds.filter { !localBookIds.contains($0) }
            
            if newBookIds.isEmpty {
                print("No new book covers to download")
            } else {
                print("Found \(newBookIds.count) new book covers to download: \(newBookIds.map { $0.uuidString })")
                await downloadBookCoversFromStorage(ids: newBookIds)
            }
            
        } catch {
            print("Error checking for new book covers: \(error)")
        }
    }
    
    func downloadBookCoversFromStorage(ids: [UUID]? = nil) async {
        guard let url = URL(string: baseAPIurlString+"/api/bookCovers") else {
            print("invalid api url")
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        
        // If specific IDs are provided, make a POST request with the IDs
        if let ids = ids {
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let requestBody = ["bookIds": ids.map { $0.uuidString }]
            
            do {
                request.httpBody = try JSONEncoder().encode(requestBody)
            } catch {
                print("error encoding request body: \(error)")
                return
            }
            
            print("getting book covers for specific IDs from storage...")
        } else {
            // Default GET request for all covers
            request.httpMethod = "GET"
            print("getting all book covers from storage...")
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let decodedBooksInfo = try JSONDecoder().decode([StorageBookInfo].self, from: data)
            
            await withTaskGroup(of: Void.self) { group in
                for bookInfo in decodedBooksInfo {
                    group.addTask {
                        await self.downloadBookCoverToDocuments(bookInfo: bookInfo)
                    }
                }
                
                // Wait for all downloads to complete
                for await _ in group {
                    // Each download completes
                }
            }
            
            print("✅ All book covers downloaded successfully")
            
        } catch {
            print("error loading covers from storage: \(error)")
        }
    }
    
    func downloadBookCoverToDocuments(bookInfo: StorageBookInfo) async {
        let newBookDirectory = (documentsPath as NSString)
            .appendingPathComponent("\(Constants.downloadedBooksPath)/\(bookInfo.id)")
        let newBookUrl = URL(filePath: newBookDirectory)
        print("downloading book cover to documents: \(newBookUrl)")
        do {
            try fileManager.createDirectory(at: newBookUrl, withIntermediateDirectories: true)
            
            guard let coverImgUrl = URL(string: bookInfo.coverUrlString),
                  let metadataUrl = URL(string: bookInfo.metadataUrlString) else {
                print("Invalid cover or metadata URLs");
                return
            }
            
            // Download cover image
            var coverRequest = URLRequest(url: coverImgUrl)
            coverRequest.httpMethod = "GET"
            coverRequest.timeoutInterval = 10
            coverRequest.allHTTPHeaderFields = ["accept": "*/*"]
            
            let (coverData, _) = try await URLSession.shared.data(for: coverRequest)
            
            // Save cover image
            let coverFileUrl = newBookUrl.appendingPathComponent("coverImage.jpg")
            try coverData.write(to: coverFileUrl)
            print("Cover image saved to: \(coverFileUrl.path)")
            
            // Download metadata
            var metadataRequest = URLRequest(url: metadataUrl)
            metadataRequest.httpMethod = "GET"
            metadataRequest.timeoutInterval = 10
            metadataRequest.allHTTPHeaderFields = ["accept": "*/*"]
            
            let (metadataData, _) = try await URLSession.shared.data(for: metadataRequest)
            
            // Save metadata (assuming it's JSON)
            let metadataFileUrl = newBookUrl.appendingPathComponent("metadata.json")
            try metadataData.write(to: metadataFileUrl)
            
            print("Metadata saved to: \(metadataFileUrl.path)")
        } catch {
            print("Error downloading book data: \(error)")
        }
    }
    
    func downloadBookFromStorageToDocuments(_ id: UUID, _ pageCount: Int, _ langs: [String]) async -> Void {
        let urlString = "\(baseAPIurlString)/api/bookPages/\(id.uuidString)"
        let langsParam = langs.joined(separator: ",")
        let fullURL = "\(urlString)?pageCount=\(pageCount)&langs=\(langsParam)"
        print("--------------------------------------------------------------------")
        print(fullURL)
        print("--------------------------------------------------------------------")
        guard let url = URL(string: fullURL) else {
            print("Invalid API URL: \(fullURL)")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        request.allHTTPHeaderFields = ["accept": "application/json"]
        
        print("Downloading book pages for \(id)...")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let JSONString = String(data: data, encoding: String.Encoding.utf8) {
               print(JSONString)
            }
            let response = try JSONDecoder().decode(BookPagesResponse.self, from: data)
            
            guard response.success else {
                print("Server returned error: \(response.error ?? "Unknown error")")
                return
            }
            
            print("Got \(response.pages.count) pages URLs for book \(id)")
            
            // Create book directory structure
            let bookDirectory = (documentsPath as NSString)
                .appendingPathComponent("\(Constants.downloadedBooksPath)/\(id)")
            let pagesDirectory = (bookDirectory as NSString)
                .appendingPathComponent(Constants.pagesDirectoryName)
            
            try fileManager.createDirectory(atPath: pagesDirectory, withIntermediateDirectories: true)
            
            // Download all pages using TaskGroup
            await withTaskGroup(of: Void.self) { group in
                for pageUrls in response.pages {
                    group.addTask {
                        await self.downloadSinglePage(pageUrls: pageUrls, bookDirectory: bookDirectory, langs: langs)
                    }
                }
                
                // Wait for all page downloads to complete
                for await _ in group {
                    // Each page download completes
                }
            }
            
            print("All pages downloaded successfully for book \(id)")
            
        } catch {
            print("Error downloading book pages: \(error)")
        }
    }
    
    private func downloadSinglePage(pageUrls: PageUrls, bookDirectory: String, langs: [String]) async {
        let pageDirectory = (bookDirectory as NSString)
            .appendingPathComponent("\(Constants.pagesDirectoryName)/\(pageUrls.pageNumber)")
        
        do {
            try fileManager.createDirectory(atPath: pageDirectory, withIntermediateDirectories: true)
            
            // Download background image
            if let bgImageUrl = URL(string: pageUrls.bgImageUrlString) {
                let bgImageData = try await URLSession.shared.data(from: bgImageUrl).0
                let bgImagePath = (pageDirectory as NSString).appendingPathComponent(Constants.backgroundImageName)
                try bgImageData.write(to: URL(fileURLWithPath: bgImagePath))
                print("Downloaded background image for page \(pageUrls.pageNumber)")
            }
            
            // Download language-specific content
            for lang in langs {
                guard let langUrls = pageUrls.languages[lang] else {
                    print("No URLs for language \(lang) on page \(pageUrls.pageNumber)")
                    continue
                }
                
                // Create language directory
                let langDirectory = (pageDirectory as NSString)
                    .appendingPathComponent("\(Constants.langDirName)/\(lang)")
                try fileManager.createDirectory(atPath: langDirectory, withIntermediateDirectories: true)
                
                // Download audio file
                if let audioUrl = URL(string: langUrls.audioUrlString) {
                    let audioData = try await URLSession.shared.data(from: audioUrl).0
                    let audioPath = (langDirectory as NSString).appendingPathComponent(Constants.audioFileName)
                    try audioData.write(to: URL(fileURLWithPath: audioPath))
                    print("Downloaded audio for page \(pageUrls.pageNumber), language \(lang)")
                }
                
                // Download text file
                if let textUrl = URL(string: langUrls.textUrlString) {
                    let textData = try await URLSession.shared.data(from: textUrl).0
                    let textPath = (langDirectory as NSString).appendingPathComponent(Constants.textFileName)
                    try textData.write(to: URL(fileURLWithPath: textPath))
                    print("Downloaded text for page \(pageUrls.pageNumber), language \(lang)")
                }
            }
            
        } catch {
            print("Error downloading page \(pageUrls.pageNumber): \(error)")
        }
    }
    
    func getBook(named bookName: String) -> Book? {
        let normalizedName = convertToDirectoryName(bookName)
        return getAllBooks("en").first { convertToDirectoryName($0.metadata.name["en"] ?? "") == normalizedName }
    }
    
    // MARK: - Private Helper Methods
    
    private func loadBooksFromDirectory(_ directoryPath: String, type: BookType, _ lang: String) -> [Book] {
        //print("loading books from \(directoryPath)")
        guard let bookDirectories = try? fileManager.contentsOfDirectory(atPath: directoryPath) else {
            print("no contents for \(directoryPath)")
            return []
        }
        print("BOOK DIRECTORIES FOR \(type.rawValue): \(bookDirectories)")
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
    
    private func loadPages(fromBookPath bookPath: String, pageCount: Int, _ lang: String, showLogs: Bool = false) -> [Page] {
        if showLogs {
            return loadPagesWithLogs(fromBookPath: bookPath, pageCount: pageCount, lang)
        } else {
            return loadPagesNoLogs(fromBookPath: bookPath, pageCount: pageCount, lang)
        }
    }

    private func loadPagesWithLogs(fromBookPath bookPath: String, pageCount: Int, _ lang: String) -> [Page] {
        var pages: [Page] = []
        let pagesPath = (bookPath as NSString).appendingPathComponent(Constants.pagesDirectoryName)
        
        print("  Starting to load \(pageCount) pages from book path: \(bookPath)")
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
        
        print("\n Finished loading pages. Total loaded: \(pages.count)/\(pageCount)")
        return pages
    }

    private func loadPagesNoLogs(fromBookPath bookPath: String, pageCount: Int, _ lang: String) -> [Page] {
        var pages: [Page] = []
        let pagesPath = (bookPath as NSString).appendingPathComponent(Constants.pagesDirectoryName)
        
        for pageNumber in 1...pageCount {
            let pagePath = (pagesPath as NSString).appendingPathComponent("\(pageNumber)")
            let pageImagePath = (pagePath as NSString).appendingPathComponent(Constants.backgroundImageName)
            
            let langsPath = (pagePath as NSString).appendingPathComponent(Constants.langDirName)
            let langPath = (langsPath as NSString).appendingPathComponent(lang)
            
            let textPath = (langPath as NSString).appendingPathComponent(Constants.textFileName)
            guard var text = try? String(contentsOfFile: textPath, encoding: .utf8) else {
                continue
            }
            text = text.replacingOccurrences(of: "\n", with: " ") //
            
            let audioPath = (langPath as NSString).appendingPathComponent(Constants.audioFileName)
            
            pages.append(Page(
                pageNumber: pageNumber,
                text: text,
                bgImagePath: pageImagePath,
                audioPath: audioPath
            ))
        }
        
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
    
    public func deleteBookPages(id: UUID) {
        // Only delete pages folder from downloaded books directory
        let downloadedBooksPath = (documentsPath as NSString).appendingPathComponent(Constants.downloadedBooksPath)
        let bookDirectory = (downloadedBooksPath as NSString).appendingPathComponent(id.uuidString)
        let pagesDirectory = (bookDirectory as NSString).appendingPathComponent(Constants.pagesDirectoryName)
        let pagesUrl = URL(fileURLWithPath: pagesDirectory)
        
        // Check if the pages directory exists
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: pagesDirectory, isDirectory: &isDirectory) && isDirectory.boolValue else {
            print("Pages directory does not exist for book ID: \(id)")
            return
        }
        
        do {
            // Remove only the Pages directory and all its contents
            try fileManager.removeItem(at: pagesUrl)
            print("Successfully deleted pages for book with ID: \(id)")
        } catch {
            print("Error deleting pages for book with ID \(id): \(error)")
        }
    }
    
    func refreshBookCovers() async {
        await checkAndDownloadNewBookCovers()
    }
}
