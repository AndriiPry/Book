//
//  AudioLibraryApp.swift
//  AudioLibrary
//
//  Created by Oleksii on 07.08.2025.
//

import SwiftUI

@main
struct AudioLibraryApp: App {
    let libraryManager = LibraryFileManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
