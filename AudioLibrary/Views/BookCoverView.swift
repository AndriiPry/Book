//
//  BookCoverView.swift
//  AudioLibrary
//
//  Created by Oleksii on 08.08.2025.
//

import SwiftUI

struct BookCoverView: View {
    let book: Book
    @State var coverImage: UIImage = UIImage(systemName: "house.fill")!
    @State var bookThemeColor: Color = Color.black
    @Binding var isPortrait: Bool
    @Binding var language: String
    @State private var isDownloading: Bool = false
    @State private var downloadProgress: Double = 0.0
    @State private var isDeleting: Bool = false
    @State private var showDeleteAlert: Bool = false
    
    var onClickDownload: ((UUID, Int, [String]) async -> Void)? = nil
    var onClickDelete: ((UUID) -> Void)? = nil
    
    @State private var isDownloadCompleted: Bool = false

    var onFinishDownload: (() -> Void)? = nil
    var onFinishDelete: (() -> Void)? = nil

    private var isDownloadedCoverOnly: Bool {
        return book.bookType == .downloaded && book.pages.isEmpty && !isDownloadCompleted
    }
    
    private var isDownloadedWithPages: Bool {
        return book.bookType == .downloaded && !book.pages.isEmpty
    }
    
    var titleFontSize: CGFloat {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return isPortrait ? 20 : 27
        default:
            if (book.metadata.name[language]?.count ?? 0) < 19 {return 24} else {return 20}
        }
    }
    
    var coverWidth: CGFloat {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return isPortrait ? 220 : 320
        default:
            return isPortrait ? 320 : 220
        }
    }
    
    var coverHeight: CGFloat {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return isPortrait ? 250 : 350
        default:
            return isPortrait ? 320 : 250
        }
    }
    
    // Constants for card design
    private enum Constants {
        static let cornerRadius: CGFloat = 20
        static let titlePadding: CGFloat = 3
        static let overlayOpacity: Double = 0.3
        static let backPageOffset: CGFloat = 8
        static let spineWidth: CGFloat = 12
        static let colorTintOpacity: Double = 0.6
        static let downloadButtonSize: CGFloat = 44
        static let progressRingWidth: CGFloat = 8
        static let deleteButtonSize: CGFloat = 36
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.cornerRadius)
                        .fill(bookThemeColor.opacity(Constants.colorTintOpacity))
                )
                .frame(width: coverWidth, height: coverHeight)
                .offset(x: Constants.backPageOffset, y: Constants.backPageOffset)
            
            ZStack(alignment: .bottom) {
                Image(uiImage: coverImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: coverWidth, height: coverHeight)
                    .clipped()
                    .opacity(isDownloadedCoverOnly ? 0.6 : 1.0) // Reduce opacity for cover-only books
                
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        ZStack {
                            Rectangle()
                                .fill(bookThemeColor.opacity(Constants.colorTintOpacity))
                            
                            Text(book.metadata.name[language] ?? "")
                                .font(.custom("Avenir-Heavy", size: titleFontSize))
                                .foregroundStyle(.white)
                                .padding(.bottom, Constants.titlePadding)
                                .shadow(radius: 2)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                        }
                    )
                    .frame(height: coverHeight * 0.25)
            }
            .frame(width: coverWidth, height: coverHeight)
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
            .shadow(color: .black.opacity(0.3), radius: 15, x: 5, y: 5)
            .overlay {
                if isDownloadedCoverOnly {
                    // Overlay for cover-only downloaded books (need to download pages)
                    Color.black.opacity(0.4)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
                    
                    if isDownloading {
                        // Simple loading indicator
                        VStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(2.0)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        .frame(width: 100, height: 100)
                        .background(Color.black.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    } else {
                        // Download button
                        Button(action: {
                            startDownloadingPages()
                        }) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: Constants.downloadButtonSize))
                                .foregroundColor(.blue)
                                .background(Circle().fill(.white))
                                .shadow(radius: 5)
                        }
                    }
                } else if isDownloadedWithPages && !book.pages.isEmpty {
                    // Delete button for downloaded books with pages (only if pages exist)
                    VStack {
                        HStack {
                            Spacer()
                            if isDeleting {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(width: Constants.deleteButtonSize, height: Constants.deleteButtonSize)
                                    .background(Circle().fill(.red.opacity(0.8)))
                                    .shadow(radius: 3)
                            } else {
                                Button(action: {
                                    showDeleteAlert = true
                                }) {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                        .frame(width: Constants.deleteButtonSize, height: Constants.deleteButtonSize)
                                        .background(Circle().fill(.red.opacity(0.8)))
                                        .shadow(radius: 3)
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(12)
                }
            }
        }
        .alert("Delete Book Pages", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                startDeletingPages()
            }
        } message: {
            Text("Are you sure you want to delete the pages for '\(book.metadata.name[language] ?? "this book")'? You'll need to download them again to read the book.")
        }
        .onAppear(perform: {
            coverImage = getImage(at: book.coverImagePath ?? "") ?? UIImage(systemName: "house.fill")!
            setThemeColor()
            print(book.bookType)
        })
    }
    
    private func startDownloadingPages() {
        isDownloading = true
        downloadProgress = 0.0
        
        Task {
            await downloadBookPages()
        }
    }
    
    private func startDeletingPages() {
        isDeleting = true
        
        Task {
            await deleteBookPages()
        }
    }
    
    private func downloadBookPages() async {
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.3)) {
                isDownloading = true
            }
        }
        
        if onClickDownload != nil {
            await onClickDownload!(book.id, book.metadata.pageCount, book.metadata.langs)
        }
        
        // Complete the download
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.3)) {
                isDownloading = false
                isDownloadCompleted = true
                onFinishDownload?()
            }
            print("Download completed for book: \(book.metadata.name[language] ?? "")")
        }
    }
    
    private func deleteBookPages() async {
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.3)) {
                isDeleting = true
            }
        }
        
        // Call the delete function
        onClickDelete?(book.id)
        
        // Small delay to show the deletion animation
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        // Complete the deletion
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.3)) {
                isDeleting = false
                onFinishDelete?()
            }
            print("Deletion completed for book: \(book.metadata.name[language] ?? "")")
        }
    }
    
    private func setThemeColor() {
        guard let avgColor = coverImage.averageColor else {
            bookThemeColor = Color.black
            return
        }
        bookThemeColor = Color(avgColor)
    }
    
    private func getImage(at path: String) -> UIImage? {
        return UIImage(contentsOfFile: path)
    }
}

struct BookCoverView_Previews: PreviewProvider {
    static let libM: LibraryFileManager = .shared
    @State static var p = true
    @State static var l = "ua"
    static var previews: some View {
        if let book = libM.getBook(named: "The Rabbit and the Computer(lcl)") {
            BookCoverView(book: book, isPortrait: $p, language: $l)
                //.previewInterfaceOrientation(.landscapeRight)
        } else {
            Text("Book not found")
        }
    }
}
