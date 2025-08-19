//
//  BookCoverView.swift
//  AudioLibrary
//
//  Created by Oleksii on 08.08.2025.
//

import SwiftUI

struct BookCoverView: View {
    let book: Book
    @State var coverImage: UIImage = UIImage(systemName: "star.fill")!
    @State var bookThemeColor: Color = Color.black
    @Binding var isPortrait: Bool
    @Binding var language: String
    
    var titleFontSize: CGFloat {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return isPortrait ? 20 : 27
        default:
            if (book.metadata.name[language]?.count ?? 0) < 25 {return 24} else {return 20}
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
        // MARK: - SIZE
        
        
        static let cornerRadius: CGFloat = 20
        static let titlePadding: CGFloat = 3
        static let overlayOpacity: Double = 0.3
        static let backPageOffset: CGFloat = 8
        static let spineWidth: CGFloat = 12
        static let colorTintOpacity: Double = 0.6
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
        }
        .onAppear(perform: {
            coverImage = getImage(at: book.coverImagePath ?? "") ?? UIImage(systemName: "star.fill")!
            setThemeColor()
        })
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
    
    private func getAudio(at path: String) -> URL? {
        return URL(fileURLWithPath: path)
    }
}

struct BookCoverView_Previews: PreviewProvider {
    static let libM: LibraryFileManager = .shared
    @State static var p = false
    @State static var l = "en"
    static var previews: some View {
        if let book = libM.getBook(named: "The Rabbit and the Computer") {
            BookCoverView(book: book, isPortrait: $p, language: $l)
                .previewInterfaceOrientation(.landscapeRight)
        } else {
            Text("Book not found")
        }
    }
}
