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
    @State private var language: String = "ua"

    var body: some View {
        ZStack {
            if readyToShowPages, let sp = selectedPages {
                PagesView(pages: sp, clickedHomeButton: $clickedHomeButton)
                    .transition(.opacity)
            } else {
                LibraryView(selectedPages: $selectedPages, language: $language)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: readyToShowPages)
        .onChange(of: selectedPages) {
            readyToShowPages = (selectedPages?.isEmpty == false)
        }
        .onChange(of: clickedHomeButton) {
            if clickedHomeButton {
                selectedPages = nil
                readyToShowPages = false
                clickedHomeButton = false
            }
        }
    }
}


#Preview(traits: .landscapeRight) {
    LibraryContainerView()
}
