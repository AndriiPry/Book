//
//  AudioPlayerDelegate.swift
//  AudioLibrary
//
//  Created by Oleksii on 09.08.2025.
//

import AVFAudio

class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    let onAudioFinished: () -> Void
    let onAudioStarted: () -> Void
    
    init(onAudioFinished: @escaping () -> Void, onAudioStarted: @escaping () -> Void) {
        self.onAudioFinished = onAudioFinished
        self.onAudioStarted = onAudioStarted
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onAudioFinished()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Audio decode error: \(error?.localizedDescription ?? "Unknown error")")
        onAudioFinished()
    }
}
