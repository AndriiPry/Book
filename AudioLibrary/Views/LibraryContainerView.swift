//
//  LibraryContainerView.swift
//  AudioLibrary
//
//  Created by Oleksii on 09.08.2025.
//

import SwiftUI

struct LibraryContainerView: View {
    @State private var selectedPages: [Page]?
    @State private var readyToShowPages = false
    @State private var clickedHomeButton = false
    @State private var language: String = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "ua"
    @State private var isInitializing = true // Track initialization state
    private var availableLanguages: [String] = ["ua", "en"]
    
    @State private var isPortrait = true
    private var libFileManager = LibraryFileManager.shared

    var body: some View {
        ZStack {
            ZStack(alignment: .topTrailing) {
                if readyToShowPages, let sp = selectedPages, sp.count > 0 {
                    PagesView(pages: sp, clickedHomeButton: $clickedHomeButton, $isPortrait)
                        .transition(.opacity)
                } else {
                    LibraryView(
                        selectedPages: $selectedPages,
                        language: $language,
                        isInitializing: $isInitializing
                    )
                    .transition(.opacity)
                }
                
                if !readyToShowPages {
                    Menu {
                        ForEach(availableLanguages, id: \.self) { lang in
                            Button(action: { language = lang }) {
                                Text(languageName(for: lang))
                            }
                        }
                    } label: {
                        Label(language.uppercased(), systemImage: "globe")
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .padding()
                    }.transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: readyToShowPages)
            
            if isInitializing {
                LoadingOverlayView()
                    .transition(.opacity)
                    .zIndex(1000)
            }
        }
        .onChange(of: selectedPages) {
            readyToShowPages = (selectedPages?.isEmpty == false)
        }
        .onChange(of: language) {
            UserDefaults.standard.set(language, forKey: "selectedLanguage")
        }
        .onChange(of: clickedHomeButton) {
            if clickedHomeButton {
                selectedPages = nil
                readyToShowPages = false
                clickedHomeButton = false
            }
        }
        .onAppear() {
            print(libFileManager.downloadedDirectoryExists)
            // LibraryView will handle initialization now
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            updateOrientation()
        }
    }

    private func languageName(for code: String) -> String {
        switch code {
        case "ua": return "Українська"
        case "en": return "English"
        default: return code
        }
    }
    
    private func updateOrientation() {
        guard let scene = UIApplication.shared.windows.first?.windowScene else { return }
        self.isPortrait = scene.interfaceOrientation.isPortrait
    }
}

// Loading Overlay View
struct LoadingOverlayView: View {
    @State private var isRotating = 0.0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Loading text
//                Text("Loading Library...")
//                    .font(.title2)
//                    .fontWeight(.medium)
//                    .foregroundColor(.white)
                
                // Progress indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.8))
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            )
        }
        .zIndex(1000) // Ensure it's on top
    }
}

// Alternative simpler loading view
struct SimpleLoadingView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack {
                ProgressView()
                    .scaleEffect(2.0)
                    .padding(.bottom, 20)
                
                Text("Initializing Library...")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview(traits: .landscapeRight) {
    LibraryContainerView()
}

#Preview {
    LibraryContainerView()
}
