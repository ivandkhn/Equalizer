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
            newValue ? player.play() : player.stop()
        }
    }
    
    var isPaused: Bool {
        get {
            return player.isPaused
        }
        set {
            toConsole("set to \(newValue)")
            player.pause()
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

    init() {
        audioFile = nil
        do {
            audioFile = try AKAudioFile(readFileName: "test3.wav")
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
    
    func initBeforePlaying() -> Bool {
        //let ringMod = AKRingModulator(player)
        AudioKit.output = player //or = ringmod
        
        player.isLooping = true
        try? AudioKit.start()
        return true
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
