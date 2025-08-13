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
            return 220
        }
    }

    var body: some View {
        ZStack {
            backgroundGradient()
            contentScrollView()
        }
        .onAppear {
            loadBooks()
            updateOrientation()
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
            .padding(spacing)
        }
    }

    private func bookRowView(row: [Book]) -> some View {
        HStack(spacing: spacing) {
            ForEach(row, id: \.id) { book in
                bookCover(book)
            }
            if row.count < 3 {
                ForEach(0..<(3 - row.count), id: \.self) { _ in
                    Color.clear.frame(width: coverWidth)
                }
            }
        }
    }

    private func bookCover(_ book: Book) -> some View {
        BookCoverView(book: book, isPortrait: $isPortrait, language: $language)
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
        //print(isPortrait)
    }

    private func chunkedBooks() -> [[Book]] {
        stride(from: 0, to: books.count, by: 3).map {
            Array(books[$0..<min($0 + 3, books.count)])
        }
    }
}

struct LibraryView_Previews: PreviewProvider {
    @State static var sp: [Page]?
    @State static var l: String = "ua"
    static var previews: some View {
      LibraryView(selectedPages: $sp, language: $l)
            .previewInterfaceOrientation(.landscapeRight)
    }
}
