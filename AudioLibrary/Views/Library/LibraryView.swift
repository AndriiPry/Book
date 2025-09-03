//
//  LibraryView.swift
//  AudioLibrary
//
//  Created by Oleksii on 09.08.2025.
//

import SwiftUI

struct LibraryView: View {
    let libM: LibraryFileManager = .shared
    @State private var books: [Book] = []
    @Binding var selectedPages: [Page]?
    @State private var tappedBookId: UUID? = nil
    @State private var isPortrait = true
    @Binding var language: String
    @Binding var isInitializing: Bool
    
    private var spacing: CGFloat {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return 40
        default: return 20
        }
    }
    
    var coverWidth: CGFloat {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return isPortrait ? 220 : 320
        default:
            return isPortrait ? 150 : 220
        }
    }
    
    var coverHeight: CGFloat {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return isPortrait ? 250 : 350
        default:
            return isPortrait ? 170 : 250
        }
    }

    private var rowWidth: CGFloat {
        let booksPerRow = UIDevice.current.userInterfaceIdiom == .pad ? 3 : (isPortrait ? 2 : 3)
        return CGFloat(booksPerRow) * coverWidth + CGFloat(booksPerRow - 1) * spacing
    }

    var body: some View {
        ZStack {
            backgroundGradient()
            contentScrollView()
                .padding(.top, 20)
                .refreshable {
                    await libM.refreshBookCovers()
                    loadBooks()
                }
        }
        .onAppear {
            //loadBooks()
            initializeAndLoadBooks()
            updateOrientation()
        }
        .onChange(of: language) {
            loadBooks()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            updateOrientation()
        }
    }

    private func backgroundGradient() -> some View {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.2, blue: 0.4),
                Color(red: 0.2, green: 0.3, blue: 0.6),
                Color(red: 0.3, green: 0.4, blue: 0.7)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private func contentScrollView() -> some View {
        ScrollView {
            let rows = chunkedBooks()
            VStack(spacing: spacing) {
                ForEach(rows.indices, id: \.self) { rowIndex in
                    bookRowView(row: rows[rowIndex])
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .ignoresSafeArea(.all, edges: .horizontal)
    }

    private func bookRowView(row: [Book]) -> some View {
        HStack(spacing: spacing) {
            ForEach(row, id: \.id) { book in
                bookCover(book)
            }
        }
        .frame(width: rowWidth, alignment: .leading)
    }

    private func bookCover(_ book: Book) -> some View {
        BookCoverView(book: book,
                      isPortrait: $isPortrait,
                      language: $language,
                      onClickDownload: book.bookType == .downloaded ? libM.downloadBookFromStorageToDocuments : nil,
                      onClickDelete: libM.deleteBookPages,
                      onFinishDownload: loadBooks,
                      onFinishDelete: loadBooks,
                      gettitleFontSize: getTitleFontSize,
                      coverWidth: coverWidth,
                      coverHeight: coverHeight
            )
            .scaleEffect(tappedBookId == book.id ? 0.95 : 1.0)
            .opacity(tappedBookId == book.id ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: tappedBookId)
            .onTapGesture {
                tappedBookId = book.id
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    tappedBookId = nil
                    selectedPages = book.pages
                }
            }
    }

    private func loadBooks() {
        books = libM.getAllBooks(language)
    }
    
    private func updateOrientation() {
        guard let scene = UIApplication.shared.windows.first?.windowScene else { return }
        self.isPortrait = scene.interfaceOrientation.isPortrait
    }

    private func chunkedBooks() -> [[Book]] {
        let booksPerRow = UIDevice.current.userInterfaceIdiom == .pad ? 3 : (isPortrait ? 2 : 3)
        return stride(from: 0, to: books.count, by: booksPerRow).map {
            Array(books[$0..<min($0 + booksPerRow, books.count)])
        }
    }
    
    private func initializeAndLoadBooks() {
        Task {
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isInitializing = true
                }
            }
            
            //await libM.initializeDownloadedDir()
            await libM.ensureInitialized()
            
            await MainActor.run {
                loadBooks()
                withAnimation(.easeInOut(duration: 0.3)) {
                    isInitializing = false
                }
            }
        }
    }
    
    private func getTitleFontSize(_ wCount: Int) -> CGFloat {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return isPortrait ? 20 : 27
        default:
            return isPortrait ? 16 : 24
        }
    }
}

struct LibraryView_Previews: PreviewProvider {
    @State static var sp: [Page]?
    @State static var l: String = "ua"
    @State static var s: Bool = false
    static var previews: some View {
        LibraryView(selectedPages: $sp, language: $l, isInitializing: $s)
            //.previewInterfaceOrientation(.landscapeRight)
    }
}
