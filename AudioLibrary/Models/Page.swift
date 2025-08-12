//
//  Page.swift
//  AudioLibrary
//
//  Created by Oleksii on 07.08.2025.
//

import Foundation

struct Page: Codable, Equatable {
    let pageNumber: Int
    let text: String
    let bgImagePath: String?
    let audioPath: String?
    
    init(pageNumber: Int, text: String, bgImagePath: String? = nil, audioPath: String? = nil) {
        self.pageNumber = pageNumber
        self.text = text
        self.bgImagePath = bgImagePath
        self.audioPath = audioPath
    }
}
