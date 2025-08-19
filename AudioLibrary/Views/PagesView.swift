//
//  PagesView.swift
//  AudioLibrary
//
//  Created by Oleksii on 09.08.2025.
//
import SwiftUI
import AVFoundation

struct PagesView: View {
    @State var pages: [Page]
    
    @State private var isAudioPaused: Bool = false
    @State private var currentPageIndex: Int = 0
    @State private var isAudioMode: Bool = false // false = read myself, true = read for me
    @State private var isAudioPlaying: Bool = false
    @Binding var clickedHomeButton: Bool
    
    @State var curlPageContainer: CurlPageContainer? = nil
    
    private enum Constants {
        static let buttonBackgroundOpacity: Double = 0.8
        static let buttonStrokeOpacity: Double = 0.3
        static let strokeWidth: CGFloat = 1
    }
    
    init(pages: [Page], clickedHomeButton: Binding<Bool>) {
        self.pages = pages
        self._clickedHomeButton = clickedHomeButton
    }
    
    // MARK: - Device-specific properties
    
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
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [.black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Background pages with page curl
                curlPageContainer?.ignoresSafeArea()
                
                // Top navigation
                VStack {
                    HStack {
                        VStack {
                            standardButton(
                                systemName: "house.fill",
                                action: handleHomeButton
                            )
                            .transition(.opacity.combined(with: .scale(scale: 0.8)))
                            
                            pageCounterView
                        }
                        .offset(y: 20)
                        .animation(.easeInOut(duration: 0.3), value: currentPageIndex)
                        
                        Spacer()
                        
                        VStack {
                            standardButton(
                                systemName: !isAudioMode ? "speaker.wave.2.fill" : "book.fill",
                                action: toggleReadingMode
                            )
                            .id("audioModeButton-\(isAudioMode)")
                            
                            if isAudioMode {
                                standardButton(
                                    systemName: isAudioPaused ? "play.fill" : "pause.fill",
                                    action: toggleAudioPlayback
                                )
                                .id("playPauseButton-\(isAudioPaused)")
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.5)).combined(with: .move(edge: .top)),
                                    removal: .opacity.combined(with: .scale(scale: 0.5)).combined(with: .move(edge: .top))
                                ))
                                .animation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0), value: isAudioPaused)
                            }
                        }
                        .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0), value: isAudioMode)
                        .offset(y: 20)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            curlPageContainer = CurlPageContainer(
                pages: $pages,
                currentIndex: $currentPageIndex,
                isAudioMode: $isAudioMode,
                isAudioPaused: $isAudioPaused,
                isAudioPlaying: $isAudioPlaying
            )
        }
    }
    
    // MARK: - UI Components
    
    private var pageCounterView: some View {
        Text("\(currentPageIndex + 1)/\(pages.count)")
            .font(.system(size: pageCounterFontSize, weight: .medium))
            .foregroundColor(.white)
            .frame(width: buttonSize, height: buttonSize)
            .background(circularButtonStyle(size: buttonSize))
    }
    
    // MARK: - Action Handlers
    
    private func handleHomeButton() {
        if isAudioMode {
            toggleReadingMode()
        }
        clickedHomeButton = true
    }
    
    private func toggleReadingMode() {
        curlPageContainer?.coordinator.controller?.toggleReadingMode()
    }
    
    private func toggleAudioPlayback() {
        curlPageContainer?.coordinator.controller?.toggleAudioPlayback()
    }
}

struct PagesView_Previews: PreviewProvider {
    @State static var sb: Book?
    @State static var ch: Bool = false
    static let libM: LibraryFileManager = .shared
    static var previews: some View {
        if let book = libM.getBook(named: "The Rabbit and the Computer") {
            PagesView(pages: book.pages, clickedHomeButton: $ch)
                .previewInterfaceOrientation(.landscapeRight)
        } else {
            Text("Book not found")
        }
    }
}
