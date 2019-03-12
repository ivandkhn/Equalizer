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
    var gainControllers = [AKDryWetMixer]()
    var distortionEffect = Distortion()
    var chorusEffect = Choir()
    var allEffects = [AKNode]()
    var distortionMixer = AKDryWetMixer()
    var chorusMixer = AKDryWetMixer()
    var allDryWetMixers = [AKDryWetMixer]()
    var afterEQMixer = AKMixer()
    var finalMixer = AKMixer()
    var FFTInputTap, FFTOutputTap: AKFFTTap?
    
    enum FFTSources {
        case input, output
    }
    
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
    
    var player = AKPlayer()
    var sampleRate: Int = 0
    var samplesCount: Int64 = 0
    var audioFile: AKAudioFile?

    init(filename: URL) {
        audioFile = nil
        do {
            audioFile = try AKAudioFile(forReading: filename)
        } catch  {
            toConsole("Error while opening file")
        }
        if let file = audioFile {
            samplesCount = file.samplesCount
            sampleRate = Int(file.sampleRate)
            toConsole("samplesCount \(samplesCount), sampleRate: \(sampleRate)")
            player = AKPlayer(audioFile: (file))
        }
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
        afterEQMixer = AKMixer(gainControllers)
        
        distortionEffect = Distortion(afterEQMixer, gain: 0.5)
        chorusEffect = Choir(afterEQMixer, gain: 0.5)
        allEffects.append(distortionEffect)
        allEffects.append(chorusEffect)
        // full effect mix
        distortionMixer = AKDryWetMixer(afterEQMixer, distortionEffect, balance: 0)
        chorusMixer = AKDryWetMixer(afterEQMixer, chorusEffect, balance: 1)
        allDryWetMixers.append(distortionMixer)
        allDryWetMixers.append(chorusMixer)
        /*
        for mixer in allDryWetMixers {
            mixer.connect(to: finalMixer)
        }
        */
        chorusMixer.connect(to: finalMixer)
        FFTOutputTap = AKFFTTap(finalMixer)
        FFTInputTap = AKFFTTap(player)
        AudioKit.output = finalMixer
        player.isLooping = true
        try? AudioKit.start()
    }
    
    func getRawData() -> [Float]? {
        let frame = Int(player.currentFrame)
        if (frame <= 0) {
            return nil
        }
        guard let slice = audioFile?.floatChannelData![0][frame...frame+1024] else {
            return nil
        }
        return Array(slice)
    }
    
    func getFFTData(source: FFTSources, amplifyBy multiplier: Float) -> [Float]? {
        switch source {
        case .input:
            guard let tap = FFTInputTap else {return nil}
            return tap.fftData.map {Float($0 * multiplier)}
        case .output:
            guard let tap = FFTOutputTap else {return nil}
            return tap.fftData.map {Float($0 * multiplier)}
        }
    }
    
    func getFFTOutputData(skippingFirst startIndex: Int) -> [Float]? {
        guard let tap = FFTOutputTap else {return nil}
        return tap.fftData.map {Float($0 * 10e5)}
    }
    
    
    //MARK: -- parameters modification
    func modifyParameter(ofBand index: Int, to value: Double) {
        gainControllers[index].balance = (value+60) / 70
    }
    
    func modifyParameter(ofEffect eN: Int, ofParameter pN: Int, to value: Double) {
        if (pN == 1) {
            modifyParameter(ofEffect: eN, dryWetBalance: value)
            return
        }
        switch eN {
        case 0:
            let effect = allEffects[0] as? Distortion
            effect?.gain = value
        case 1:
            let effect = allEffects[1] as? Choir
            effect?.gain = value
        default:
            toConsole("default case!")
        }
    }
    
    func modifyParameter(ofEffect eN: Int, dryWetBalance: Double) {
        allDryWetMixers[eN].balance = dryWetBalance
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

func getGainControllerInstances(inputNode: [AKNode]) -> [AKDryWetMixer] {
    var buffer = [AKDryWetMixer]()
    let emptyNode = AKWhiteNoise(amplitude: 0)
    for node in inputNode {
        let gainController = AKDryWetMixer(emptyNode, node, balance: 0.5)
        buffer.append(gainController)
    }
    return buffer
}
