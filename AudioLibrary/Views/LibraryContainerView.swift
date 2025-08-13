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
    private var availableLanguages: [String] = ["ua", "en"]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if readyToShowPages, let sp = selectedPages {
                PagesView(pages: sp, clickedHomeButton: $clickedHomeButton)
                    .transition(.opacity)
            } else {
                LibraryView(selectedPages: $selectedPages, language: $language)
                    .transition(.opacity)
            }
            if selectedPages == nil {
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
    }

    private func languageName(for code: String) -> String {
        switch code {
        case "ua": return "Українська"
        case "en": return "English"
        default: return code
        }
    }
}

#Preview(traits: .landscapeRight) {
    LibraryContainerView()
}
