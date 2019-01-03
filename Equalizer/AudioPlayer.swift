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
            audioFile = try AKAudioFile(readFileName: "test.wav")
        } catch  {
            print("Error while opening file")
        }
        samplesCount = audioFile?.samplesCount ?? 0
        toConsole("Loaded file with \(samplesCount) samples.")
    }

    func logAmplitudes(first: Int) {
        var index = first
        if index > samplesCount {
            toConsole("index > samplesCount. Setting index = samplesCount")
            index = Int(samplesCount)
        }
        toConsole(audioFile?.floatChannelData![0][0..<index] ?? "nil")
    }
}

public func toConsole(_ message: Any, function: String = #function ) {
    print("[\(function)] \(message)")
}
