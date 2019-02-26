//
//  AudioPlayer.swift
//  Equalizer
//
//  Created by Иван Дахненко on 03/01/2019.
//  Copyright © 2019 Ivan Dakhnenko. All rights reserved.
//

import Foundation
import AudioKit

// pre-defined filtering parameters.
var initialEqualizerBands: [Double] = [100, 300, 700, 1500, 3100, 6300, 12700]
var bandsAmount = initialEqualizerBands.count + 1
let xFadeFactor = 0.1

class PlaybackEngine {
    // MARK: -- processing nodes
    var LPFilter = AKLowPassButterworthFilter()
    var BPFilters = [AKBandPassButterworthFilter]()
    var HPFilter = AKHighPassFilter()
    var allEQs = [AKNode]()
    var gainControllers = [AKBooster]()
    var distortionEffect = Distortion()
    var finalMixer = AKMixer()
    
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
    
    func initBeforePlaying() {
        BPFilters = getMiddleFiltersInstances(
            inputNode: player, bands: initialEqualizerBands
        )
        LPFilter = AKLowPassButterworthFilter(
            player, cutoffFrequency: initialEqualizerBands[0]
        )
        HPFilter = AKHighPassFilter(
            player,
            cutoffFrequency: initialEqualizerBands[initialEqualizerBands.count-1]
        )
        
        //attach all nodes together
        allEQs.append(LPFilter)
        allEQs.append(contentsOf: BPFilters)
        allEQs.append(HPFilter)
        gainControllers = getGainControllerInstances(inputNode: allEQs)
        finalMixer = AKMixer(gainControllers)
        distortionEffect = Distortion(finalMixer, gain: 0.5)
        AudioKit.output = distortionEffect
        player.isLooping = true
        try? AudioKit.start()
    }
    
    func modifyParameter(ofBand index: Int, to value: Double) {
        gainControllers[index].dB = value
    }
    
    func modifyParameter(ofEffect eN: Int, ofParameter pN: Int, to value: Double) {
        // distortionEffect.gain = value
    }
    
    func modifyParameter(ofEffect eN: Int, enabled: Bool) {
        // TODO
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

func getMiddleFiltersInstances(inputNode: AKPlayer, bands: [Double]) -> [AKBandPassButterworthFilter] {
    var buffer = [AKBandPassButterworthFilter]()
    for index in 0..<bands.count - 1 {
        let current = bands[index]
        let next = bands[index+1]
        let center = (current + next)/2
        let bw = floor((next - current) * (1 + xFadeFactor))
        let filter = AKBandPassButterworthFilter(
            inputNode,
            centerFrequency: center,
            bandwidth: bw
        )
        buffer.append(filter)
        toConsole("added BP filter: center: \(center), bw: \(bw)")
    }
    return buffer;
}

func getGainControllerInstances(inputNode: [AKNode]) -> [AKBooster] {
    var buffer = [AKBooster]()
    for node in inputNode {
        let gainController = AKBooster(node, gain: 1.0)
        buffer.append(gainController)
    }
    return buffer
}
