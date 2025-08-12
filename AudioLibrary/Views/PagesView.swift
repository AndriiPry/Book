//
//  PagesView.swift
//  AudioLibrary
//
//  Created by Oleksii on 09.08.2025.
//
import SwiftUI
import AVFoundation

struct PagesView: View {
    let pages: [Page]
    @State private var currentPageIndex: Int = 0
    @State private var dragOffset: CGSize = .zero
    @State private var isAudioMode: Bool = false // false = read myself, true = read for me
    @State private var audioPlayer: AVAudioPlayer?
    @State private var dragStartX: CGFloat = 0
    @State private var isAudioPlaying: Bool = false
    @State private var audioDelegate: AudioPlayerDelegate?
    @State private var isTransitioning: Bool = false
    @Binding var clickedHomeButton: Bool
    
    @State public var PagesImages: [Int: Image] = [:]
    @State private var loadedPageImages: Set<Int> = []
    @State private var isLoadingImages: Set<Int> = []
    
    private enum Constants {
        static let pageChangeThreshold: CGFloat = 100
        static let maxDragOffset: CGFloat = 300
        static let textPadding: CGFloat = 20
        static let textBackgroundOpacity: Double = 0.85
        static let cornerRadius: CGFloat = 16
        static let progressBarHeight: CGFloat = 4
        static let arrowButtonSize: CGFloat = 80
        static let pageCounterHeight: CGFloat = 40
        static let animationDuration: TimeInterval = 0.8
        static let bounceAnimationDuration: TimeInterval = 0.8
        static let preloadRange: Int = 2
    }
    
    init(pages: [Page], clickedHomeButton: Binding<Bool>) {
        self.pages = pages
        self._clickedHomeButton = clickedHomeButton
    }
    
    private var arrowsHorizontalPadding: CGFloat {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return 30
        default:
            return -30
        }
    }
    
    private var arrowsbottomPadding: CGFloat {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return 20
        default:
            return 0
        }
    }
    
    private var symbolFontSize: CGFloat {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return 42
        default:
            return 24
        }
    }
    
    private var ButtonSize: CGFloat{
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return 70
        default:
            return 50
        }
    }
    
    private var pageCounterFontSize: CGFloat {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return 28
        default:
            return 20
        }
    }
    
    private var pageCounterSize: CGFloat {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return 70
        default:
            return 50
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [
                        .black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea() // 

                // Background pages
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    PageView(
                        page: page,
                        geometry: geometry,
                        offset: offsetForPage(at: index, screenWidth: UIScreen.screenWidth),
                        img: PagesImages[page.pageNumber]
                    )
                }
                
                // Bottom navigation
                VStack {
                    Spacer()
                    
                    HStack {
                        // prev page
                        Button(action: goToPreviousPage) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: Constants.arrowButtonSize, height: Constants.arrowButtonSize)
                                .background(
                                    Circle()
                                        .fill(Color.gray.opacity(0.7))
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .opacity(currentPageIndex > 0 ? 1.0 : 0.3)
                        .disabled(currentPageIndex <= 0)
                        
                        Spacer()
                        
                        // next page
                        Button(action: goToNextPage) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: Constants.arrowButtonSize, height: Constants.arrowButtonSize)
                                .background(
                                    Circle()
                                        .fill(Color.gray.opacity(0.7))
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .opacity(currentPageIndex < pages.count - 1 ? 1.0 : 0.3)
                        .disabled(currentPageIndex >= pages.count - 1)
                    }
                    .padding(.horizontal, arrowsHorizontalPadding)
                    .padding(.bottom, arrowsbottomPadding)
                }
                
                VStack {
                    HStack {
                        VStack {
                            Button(action: {
                                if isAudioMode {
                                    toggleReadingMode()
                                }
                                clickedHomeButton = true
                            }) {
                                Image(systemName: "house.fill")
                                    .font(.system(size: symbolFontSize, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: ButtonSize, height: ButtonSize)
                                    .background(
                                        Circle()
                                            .fill(Color.gray.opacity(0.8))
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            
                            Text("\(currentPageIndex + 1)/\(pages.count)")
                                .font(.system(size: pageCounterFontSize, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: ButtonSize, height: ButtonSize)
                                .background(
                                    Circle()
                                        .fill(Color.gray.opacity(0.8))
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                                .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0), value: isTransitioning)
                        }.offset(y:20)
                        
                        Spacer()
                        
                        Button(action: toggleReadingMode) {
                            Image(systemName: !isAudioMode ? "speaker.wave.2.fill" : "book.fill")
                                .font(.system(size: symbolFontSize, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: ButtonSize, height: ButtonSize)
                                .background(
                                    Circle()
                                        .fill(Color.gray.opacity(0.8))
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            loadImagesForCurrentPage()
            if isAudioMode {
                playCurrentPageAudio()
            }
        }
        .onChange(of: currentPageIndex) {
            loadImagesForCurrentPage()
        }
    }
    
    // MARK: - Lazy Image Loading
    
    private func loadImagesForCurrentPage() {
        //+ nearby
        let startIndex = max(0, currentPageIndex - Constants.preloadRange)
        let endIndex = min(pages.count - 1, currentPageIndex + Constants.preloadRange)
        
        for i in startIndex...endIndex {
            if i < pages.count {
                loadImageForPageIfNeeded(pages[i].pageNumber)
            }
        }
        
        cleanupDistantImages()
    }
    
    private func loadImageForPageIfNeeded(_ pageNumber: Int) {
        guard !loadedPageImages.contains(pageNumber),
              !isLoadingImages.contains(pageNumber),
              let page = pages.first(where: { $0.pageNumber == pageNumber }),
              let imagePath = page.bgImagePath else { return }
        
        isLoadingImages.insert(pageNumber)
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            let image = self.getImage(at: imagePath)
            
            // main thread
            DispatchQueue.main.async {
                self.isLoadingImages.remove(pageNumber)
                
                if let image = image {
                    self.PagesImages[pageNumber] = Image(uiImage: image)
                    self.loadedPageImages.insert(pageNumber)
                }
            }
        }
    }
    
    private func cleanupDistantImages() {
        let keepRange = Constants.preloadRange * 2
        let startKeep = max(0, currentPageIndex - keepRange)
        let endKeep = min(pages.count - 1, currentPageIndex + keepRange)
        
        let pagesToRemove = loadedPageImages.filter { pageNumber in
            guard let pageIndex = pages.firstIndex(where: { $0.pageNumber == pageNumber }) else { return true }
            return pageIndex < startKeep || pageIndex > endKeep
        }
        
        for pageNumber in pagesToRemove {
            PagesImages.removeValue(forKey: pageNumber)
            loadedPageImages.remove(pageNumber)
        }
    }
    
    // MARK: - Page Navigation
    
    private func offsetForPage(at index: Int, screenWidth: CGFloat) -> CGFloat {
        let baseOffset = CGFloat(index - currentPageIndex) * screenWidth
        
        if index == currentPageIndex {
            return baseOffset + dragOffset.width
        } else if index == currentPageIndex + 1 && dragOffset.width < 0 {
            return baseOffset + dragOffset.width
        } else if index == currentPageIndex - 1 && dragOffset.width > 0 {
            return baseOffset + dragOffset.width
        }
        
        return baseOffset
    }
    
    private func goToPreviousPage() {
        if currentPageIndex > 0 {
            
            if isAudioMode && isAudioPlaying {
                DispatchQueue.global(qos: .userInteractive).async {
                    stopAudio()
                }
            }
            
            // Start animation immediately
            withAnimation(.snappy(duration: Constants.animationDuration)) {
                currentPageIndex -= 1
                dragOffset = .zero
            }
            
            if isAudioMode {
                DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 1.1) {
                    playCurrentPageAudio()
                }
            }
        }
    }
    
    private func goToNextPage() {
        if currentPageIndex < pages.count - 1 {
                        if isAudioMode && isAudioPlaying {
                DispatchQueue.global(qos: .userInteractive).async {
                    stopAudio()
                }
            }
            
            withAnimation(.snappy(duration: Constants.animationDuration)) {
                currentPageIndex += 1
                dragOffset = .zero
            }
            
            if isAudioMode {
                DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 1.1) {
                    playCurrentPageAudio()
                }
            }
        }
    }
    
    private func toggleReadingMode() {
        isAudioMode.toggle()
    
        DispatchQueue.global(qos: .userInteractive).async {
            if isAudioMode {
                playCurrentPageAudio()
            } else {
                stopAudio()
            }
        }
    }
    
    // MARK: - Audio Functions
    
    private func playCurrentPageAudio() {
        guard isAudioMode,
              currentPageIndex < pages.count,
              let audioPath = pages[currentPageIndex].audioPath,
              let audioURL = getAudio(at: audioPath) else { return }
        
        do {
            let player = try AVAudioPlayer(contentsOf: audioURL)
            
            DispatchQueue.main.async {
                self.audioPlayer = player
                
                self.audioDelegate = AudioPlayerDelegate(
                    onAudioFinished: handleAudioFinished,
                    onAudioStarted: handleAudioStarted
                )
                self.audioPlayer?.delegate = self.audioDelegate
                
                // Start playback
                self.audioPlayer?.play()
                self.isAudioPlaying = true
            }
        } catch {
            print("Error playing audio: \(error)")
            DispatchQueue.main.async {
                self.isAudioPlaying = false
            }
        }
    }
    
    private func stopAudio() {
        DispatchQueue.main.async {
            self.audioPlayer?.stop()
            self.audioPlayer = nil
            self.audioDelegate = nil
            self.isAudioPlaying = false
        }
    }
    
    private func getAudio(at path: String) -> URL? {
        return URL(fileURLWithPath: path)
    }
    
    private func handleAudioFinished() {
        DispatchQueue.main.async {
            self.isAudioPlaying = false
            //print(self.currentPageIndex)
            if self.currentPageIndex < self.pages.count - 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.goToNextPage()
                }
            } else if currentPageIndex == pages.count - 1 {
                DispatchQueue.global(qos: .userInteractive).async {
                    stopAudio()
                }
                withAnimation {
                    isAudioMode = false
                }
            }
        }
    }
    
    private func handleAudioStarted() {
        DispatchQueue.main.async {
            self.isAudioPlaying = true
        }
    }
    
    private func getImage(at path: String) -> UIImage? {
        guard FileManager.default.fileExists(atPath: path) else {
            print("Image not found at path: \(path)")
            return nil
        }
        
        return UIImage(contentsOfFile: path)
    }
}

struct PagesView_Previews: PreviewProvider {
    @State static var sb: Book?
    @State static var ch: Bool = false
    static let libM: LibraryFileManager = .shared
    static var previews: some View {
        if let book = libM.getBook(named: "The Wise Deer") {
            PagesView(pages: book.pages, clickedHomeButton: $ch)
                .previewInterfaceOrientation(.landscapeRight)
        } else {
            Text("Book not found")
        }
    }
}
