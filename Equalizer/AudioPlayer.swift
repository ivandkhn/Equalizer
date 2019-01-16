//
//  AudioPlayer.swift
//  Equalizer
//
//  Created by Иван Дахненко on 03/01/2019.
//  Copyright © 2019 Ivan Dakhnenko. All rights reserved.
//

import Foundation
import AudioKit

class AudioPlayer {
    
    var isPlaying: Bool {
        get {
            return player.isPlaying
        }
        set {
            toConsole("set to \(newValue)")
            newValue ? player.play(from: 0) : player.stop()
        }
    }
    
    var pauseTime: Double = 0
    
    // there's a bug in audioKit so that isPaused() is always false.
    // so we have to handle own pause variable here
    private var isTruePaused = false
    
    var isPaused: Bool {
        get {
            return isTruePaused
            // return player.isPaused
        }
        set {
            toConsole("set to \(newValue)")
            if newValue {
                pauseTime = player.currentTime
                player.pause()
            } else {
                player.play(from: pauseTime)
            }
            isTruePaused = newValue
        }
    }
    
    var player: AKPlayer
    
    var audioFile: AKAudioFile? {
        didSet {
            if let c = audioFile?.samplesCount {
                samplesCount = c
            } else {
                samplesCount = 0
            }
        }
    }
    
    var samplesCount: Int64 = 0

    init(filename: URL) {
        audioFile = nil
        do {
            audioFile = try AKAudioFile(forReading: filename)
        } catch  {
            print("Error while opening file")
            //TODO: show error in UI
        }
        samplesCount = audioFile?.samplesCount ?? 0
        toConsole("Loaded file with \(samplesCount) samples.")
        
        
        // if you catch a forced nil unwrapping exception,
        // most probably you have just copied .wav file in /Eq folder.
        // You have to do a reference as well: drag and drop this file
        // into Xcode left panel
        player = AKPlayer(audioFile: (audioFile!))
    }
    
    func initBeforePlaying() { // -> Bool (to handle exceptions?)
        // let effect = AKRingModulator()
        AudioKit.output = player //or = effect
        
        player.isLooping = true
        try? AudioKit.start()
    }
    
    func logAmplitudes(first: Int) {
        var index = first
        if index > samplesCount {
            toConsole("index > samplesCount. Setting index = samplesCount")
            index = Int(samplesCount)
        }
        toConsole(audioFile?.floatChannelData![0][0..<index])
    }
}

public func toConsole(_ message: Any?, function: String = #function ) {
    print("[\(function)] \(message ?? "nil message")")
}
