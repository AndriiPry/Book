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
    
    // MARK: filter modifiers
    @State private var isFiltersExpanded: Bool = false
    @State private var animationID = UUID()
    @State private var filteredBooks: [Book] = []
    @State private var selectedAgeGroup: String = ""
    @State private var selectedTag: String = ""
    
    private var ageGroups: [String] {
        guard !books.isEmpty else { return [] }
        return Array(Set(books.map { $0.metadata.ageGroup })).sorted()
    }

    private var tags: [String] {
        guard !books.isEmpty else { return [] }
        return Array(Set(books.flatMap { $0.metadata.tags })).sorted()
    }
    
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

    // MARK: - Parent ScrollView
    private func contentScrollView() -> some View {
        ScrollView {
            VStack(spacing: 20) {
                headerBlock()
                filterBlock()
                booksGrid()
            }
        }
        .ignoresSafeArea(.all, edges: .horizontal)
    }

    // MARK: - 1. Header (title + recommended book)
    private func headerBlock() -> some View {
        VStack(spacing: 15) {
            topRow()
            recommendedBookView()
        }
        .padding(.top, 10)
    }

    // MARK: - 1a. Top row
    private func topRow() -> some View {
        HStack {
            Text("Recommended for you")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Spacer()

            VStack(spacing: 4) {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                Text("For Parents")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal)
    }

    // MARK: - 1b. Recommended book (or placeholder)
    private func recommendedBookView() -> some View {
        
        if let recommendedBook = books.first {
            return AnyView(
                BookCoverView(
                    book: recommendedBook,
                    isPortrait: $isPortrait,
                    language: $language,
                    onClickDownload: recommendedBook.bookType == .downloaded ? libM.downloadBookFromStorageToDocuments : nil,
                    onClickDelete: libM.deleteBookPages,
                    onFinishDownload: loadBooks,
                    onFinishDelete: loadBooks,
                    gettitleFontSize: getTitleFontSize,
                    coverWidth: UIDevice.current.userInterfaceIdiom == .pad ? 570 : 370,
                    coverHeight: UIDevice.current.userInterfaceIdiom == .pad ? 600 : 500,
                    isRecommended: true
                )
                .frame(width: UIDevice.current.userInterfaceIdiom == .pad ? 570 : 370,
                       height:
                        UIDevice.current.userInterfaceIdiom == .pad ? 600 : 500
                      )
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                .onTapGesture {
                    selectedPages = recommendedBook.pages
                }
            )
        } else {
            return AnyView(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: UIScreen.main.bounds.width - 40,
                           height: (UIScreen.main.bounds.width - 40) * 1.4)
                    .overlay(
                        Image(systemName: "book.closed")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.5))
                    )
            )
        }
    }

    // MARK: - 2. Filter section (toggle + expanded content)
    private func filterBlock() -> some View {
        VStack(spacing: 0) {
            if isFiltersExpanded {
                expandedFilters()
            }

            filterToggleButton()
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }

    // MARK: - 2a. Expanded filters
    private func expandedFilters() -> some View {
        VStack(spacing: 12) {
            ageGroupFilter()
            tagFilter()
            filterActionButtons()
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // Individual filter rows:
    private func ageGroupFilter() -> some View {
        HStack {
            Text("Age Group:")
                .foregroundColor(.white)
                .fontWeight(.medium)
            Spacer()
            Picker("Age", selection: $selectedAgeGroup) {
                Text("All Ages").tag("")
                    .foregroundStyle(.white)
                ForEach(ageGroups, id: \.self) { ageGroup in
                    Text(ageGroup).tag(ageGroup)
                        .foregroundColor(.white)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .accentColor(.white)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
        }
    }

    private func tagFilter() -> some View {
        HStack {
            Text("Tags:")
                .foregroundColor(.white)
                .fontWeight(.medium)

            Spacer()

            Picker("Tag", selection: $selectedTag) {
                Text("All Tags")
                    .tag("")
                    .foregroundColor(.white)
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .tag(tag)
                        .foregroundColor(.white)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .accentColor(.white)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
        }
    }


    private func filterActionButtons() -> some View {
        HStack(spacing: 20) {
            Spacer()
            Button(action: applyFilters) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Apply")
                }
                .foregroundColor(.green)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.green.opacity(0.2)))
            }

            Button(action: clearFilters) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                    Text("Clear")
                }
                .foregroundColor(.red)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.red.opacity(0.2)))
            }
            Spacer()
        }
    }

    // Toggle button always visible
    private func filterToggleButton() -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isFiltersExpanded.toggle()
                if !isFiltersExpanded {
                    clearFilters()
                }
            }
        }) {
            HStack {
                Image(systemName: isFiltersExpanded
                      ? "line.3.horizontal.decrease.circle.fill"
                      : "line.3.horizontal.decrease.circle")
                    .font(.title3)
                Text(isFiltersExpanded ? "Close Filters" : "Filter Books")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
            .padding(.vertical, 12)
        }
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
        .padding(.horizontal, isFiltersExpanded ? 15 : 0)
        .padding(.top, isFiltersExpanded ? 0 : 12)
        .padding(.bottom, 12)
    }

    // MARK: - 3. Books grid/list
    private func booksGrid() -> some View {
        let rows = chunkedBooks()
        return VStack(spacing: spacing) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                bookRowView(row: rows[rowIndex])
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
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
        filteredBooks = []
        selectedAgeGroup = ""
        selectedTag = ""
    }
    
    private func updateOrientation() {
        guard let scene = UIApplication.shared.windows.first?.windowScene else { return }
        self.isPortrait = scene.interfaceOrientation.isPortrait
    }

    private func chunkedBooks() -> [[Book]] {
        let displayBooks = filteredBooks.isEmpty ? books : filteredBooks
        let booksPerRow = UIDevice.current.userInterfaceIdiom == .pad ? 3 : (isPortrait ? 2 : 3)
        
        return stride(from: 0, to: displayBooks.count, by: booksPerRow).map {
            Array(displayBooks[$0..<min($0 + booksPerRow, displayBooks.count)])
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
    
    private func getTitleFontSize() -> CGFloat {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return isPortrait ? 20 : 27
        default:
            return isPortrait ? 16 : 24
        }
    }
    
    private func applyFilters() {
        guard !books.isEmpty else { return }
        
        var filtered = books
        
        // Apply age group filter
        if !selectedAgeGroup.isEmpty {
            filtered = filtered.filter { $0.metadata.ageGroup == selectedAgeGroup }
        }
        
        // Apply tag filter
        if !selectedTag.isEmpty {
            filtered = filtered.filter { book in
                book.metadata.tags.contains { tag in
                    tag.lowercased() == selectedTag.lowercased()
                }
            }
        }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            filteredBooks = filtered
            isFiltersExpanded = false
        }
        
//        print("Applied filters - Age: \(selectedAgeGroup), Tag: \(selectedTag)")
//        print("Original books: \(books.count), Filtered books: \(filteredBooks.count)")
    }

    private func clearFilters() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            selectedAgeGroup = ""
            selectedTag = ""
            filteredBooks = []
            isFiltersExpanded = false
        }
        //print("Filters cleared")
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
