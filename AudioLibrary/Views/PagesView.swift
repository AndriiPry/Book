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
    
    @State private var isAudioPaused: Bool = false
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
        
        // Button styling constants
        static let buttonBackgroundOpacity: Double = 0.8
        static let buttonStrokeOpacity: Double = 0.3
        static let arrowButtonOpacity: Double = 0.7
        static let strokeWidth: CGFloat = 1
    }
    
    init(pages: [Page], clickedHomeButton: Binding<Bool>) {
        self.pages = pages
        self._clickedHomeButton = clickedHomeButton
    }
    
    // MARK: - Device-specific properties
    
    private var arrowsHorizontalPadding: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 30 : -30
    }
    
    private var arrowsBottomPadding: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 20 : 0
    }
    
    private var symbolFontSize: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 42 : 24
    }
    
    private var buttonSize: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 70 : 50
    }
    
    private var pageCounterFontSize: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 28 : 20
    }
    
    // MARK: - Reusable Button Styles
    
    private func circularButtonStyle(size: CGFloat, backgroundOpacity: Double = Constants.buttonBackgroundOpacity) -> some View {
        Circle()
            .fill(Color.gray.opacity(backgroundOpacity))
            .stroke(Color.white.opacity(Constants.buttonStrokeOpacity), lineWidth: Constants.strokeWidth)
            .frame(width: size, height: size)
    }
    
    private func standardButton(systemName: String, action: @escaping () -> Void, opacity: Double = 1.0, disabled: Bool = false) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: symbolFontSize, weight: .medium))
                .foregroundColor(.white)
                .frame(width: buttonSize, height: buttonSize)
                .background(circularButtonStyle(size: buttonSize))
        }
        .opacity(opacity)
        .disabled(disabled)
    }
    
    private func arrowButton(systemName: String, action: @escaping () -> Void, isEnabled: Bool) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
                .frame(width: Constants.arrowButtonSize, height: Constants.arrowButtonSize)
                .background(circularButtonStyle(size: Constants.arrowButtonSize, backgroundOpacity: Constants.arrowButtonOpacity))
        }
        .opacity(isEnabled ? 1.0 : 0.3)
        .disabled(!isEnabled)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [.black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

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
                        arrowButton(
                            systemName: "chevron.left",
                            action: goToPreviousPage,
                            isEnabled: currentPageIndex > 0
                        )
                        
                        Spacer()
                        
                        arrowButton(
                            systemName: "chevron.right",
                            action: goToNextPage,
                            isEnabled: currentPageIndex < pages.count - 1
                        )
                    }
                    .padding(.horizontal, arrowsHorizontalPadding)
                    .padding(.bottom, arrowsBottomPadding)
                }
                
                // Top navigation
                VStack {
                    HStack {
                        VStack {
                            standardButton(
                                systemName: "house.fill",
                                action: handleHomeButton
                            )
                            
                            pageCounterView
                        }
                        .offset(y: 20)
                        
                        Spacer()
                        
                        VStack {
                            standardButton(
                                systemName: !isAudioMode ? "speaker.wave.2.fill" : "book.fill",
                                action: toggleReadingMode
                            )
                            
                            if isAudioMode {
                                standardButton(
                                    systemName: isAudioPaused ? "play.fill" : "pause.fill",
                                    action: toggleAudioPlayback
                                )
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .offset(y: 20)
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
    
    // MARK: - UI Components
    
    private var pageCounterView: some View {
        Text("\(currentPageIndex + 1)/\(pages.count)")
            .font(.system(size: pageCounterFontSize, weight: .medium))
            .foregroundColor(.white)
            .frame(width: buttonSize, height: buttonSize)
            .background(circularButtonStyle(size: buttonSize))
            .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0), value: isTransitioning)
    }
    
    // MARK: - Action Handlers
    
    private func handleHomeButton() {
        if isAudioMode {
            toggleReadingMode()
        }
        clickedHomeButton = true
    }
    
    // MARK: - Lazy Image Loading
    
    private func loadImagesForCurrentPage() {
        let range = getPageLoadRange()
        
        for i in range.startIndex...range.endIndex {
            if i < pages.count {
                loadImageForPageIfNeeded(pages[i].pageNumber)
            }
        }
        
        cleanupDistantImages()
    }
    
    private func getPageLoadRange() -> (startIndex: Int, endIndex: Int) {
        let startIndex = max(0, currentPageIndex - Constants.preloadRange)
        let endIndex = min(pages.count - 1, currentPageIndex + Constants.preloadRange)
        return (startIndex, endIndex)
    }
    
    private func loadImageForPageIfNeeded(_ pageNumber: Int) {
        guard !loadedPageImages.contains(pageNumber),
              !isLoadingImages.contains(pageNumber),
              let page = pages.first(where: { $0.pageNumber == pageNumber }),
              let imagePath = page.bgImagePath else { return }
        
        isLoadingImages.insert(pageNumber)
        
        DispatchQueue.global(qos: .userInitiated).async {
            let image = getImage(at: imagePath)
            
            DispatchQueue.main.async {
                isLoadingImages.remove(pageNumber)
                
                if let image = image {
                    PagesImages[pageNumber] = Image(uiImage: image)
                    loadedPageImages.insert(pageNumber)
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
        
        pagesToRemove.forEach { pageNumber in
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
        guard currentPageIndex > 0 else { return }
        
        handlePageTransition {
            currentPageIndex -= 1
        }
    }
    
    private func goToNextPage() {
        guard currentPageIndex < pages.count - 1 else { return }
        
        handlePageTransition {
            currentPageIndex += 1
        }
    }
    
    private func handlePageTransition(_ updateIndex: () -> Void) {
        if isAudioMode && isAudioPlaying {
            DispatchQueue.global(qos: .userInteractive).async {
                stopAudio()
            }
        }
        
        withAnimation(.snappy(duration: Constants.animationDuration)) {
            updateIndex()
            dragOffset = .zero
        }
        
        if isAudioMode {
            DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 1.1) {
                playCurrentPageAudio()
            }
        }
    }
    
    private func toggleReadingMode() {
        isAudioMode.toggle()
        isAudioPaused = false // Reset paused state when toggling mode
        
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
                audioPlayer = player
                setupAudioDelegate()
                
                if !isAudioPaused {
                    player.play()
                    isAudioPlaying = true
                } else {
                    player.prepareToPlay()
                    isAudioPlaying = false
                }
            }
        } catch {
            print("Error playing audio: \(error)")
            DispatchQueue.main.async {
                isAudioPlaying = false
            }
        }
    }
    
    private func setupAudioDelegate() {
        audioDelegate = AudioPlayerDelegate(
            onAudioFinished: handleAudioFinished,
            onAudioStarted: handleAudioStarted
        )
        audioPlayer?.delegate = audioDelegate
    }
    
    private func toggleAudioPlayback() {
        guard isAudioMode, let player = audioPlayer else { return }
        
        if isAudioPaused {
            player.play()
            isAudioPaused = false
            isAudioPlaying = true
        } else {
            player.pause()
            isAudioPaused = true
            isAudioPlaying = false
        }
    }
    
    private func stopAudio() {
        DispatchQueue.main.async {
            audioPlayer?.stop()
            audioPlayer = nil
            audioDelegate = nil
            isAudioPlaying = false
            isAudioPaused = false
        }
    }
    
    private func handleAudioFinished() {
        DispatchQueue.main.async {
            isAudioPlaying = false
            
            if currentPageIndex < pages.count - 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    goToNextPage()
                }
            } else {
                // Last page - exit audio mode
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
            isAudioPlaying = true
        }
    }
    
    private func getAudio(at path: String) -> URL? {
        URL(fileURLWithPath: path)
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
