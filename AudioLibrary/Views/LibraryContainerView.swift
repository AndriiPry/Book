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

    var body: some View {
        ZStack {
            if readyToShowPages, let sp = selectedPages {
                PagesView(pages: sp, clickedHomeButton: $clickedHomeButton)
                    .transition(.opacity)
            } else {
                LibraryView(selectedPages: $selectedPages)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: readyToShowPages)
        .onChange(of: selectedPages) { newValue in
            readyToShowPages = (newValue?.isEmpty == false)
        }
        .onChange(of: clickedHomeButton) { newValue in
            if newValue {
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
