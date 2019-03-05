//
//  ChoirAudioUnit.swift
//  Equalizer
//
//  Created by Иван Дахненко on 05/03/2019.
//  Copyright © 2019 Ivan Dakhnenko. All rights reserved.
//

import AVFoundation
import AudioKit

public class ChoirAudioUnit: AKAudioUnitBase {

    func setParameter(_ address: AKBoosterParameter, value: Double) {
        setParameterWithAddress(AUParameterAddress(address.rawValue), value: Float(value))
    }

    func setParameterImmediately(_ address: AKBoosterParameter, value: Double) {
        setParameterImmediatelyWithAddress(AUParameterAddress(address.rawValue), value: Float(value))
    }

    var leftGain: Double = 1.0 {
        didSet { setParameter(.leftGain, value: leftGain) }
    }

    var rightGain: Double = 1.0 {
        didSet { setParameter(.rightGain, value: rightGain) }
    }

    var rampDuration: Double = 0.0 {
        didSet { setParameter(.rampDuration, value: rampDuration) }
    }

    var rampType: Int = 0 {
        didSet {
            setParameter(.rampType, value: Double(rampType))
        }
    }

    public override func initDSP(withSampleRate sampleRate: Double,
                                 channelCount count: AVAudioChannelCount) -> UnsafeMutableRawPointer! {
        toConsole("CHOIR DSP CREATED")
        return createChoirDSP(Int32(count), sampleRate)
    }

    public override init(componentDescription: AudioComponentDescription,
                  options: AudioComponentInstantiationOptions = []) throws {
        try super.init(componentDescription: componentDescription, options: options)

        let flags: AudioUnitParameterOptions = [.flag_IsReadable, .flag_IsWritable, .flag_CanRamp]
        let leftGain = AUParameterTree.createParameter(withIdentifier: "leftOffset",
                                                       name: "Left Offset Amount",
                                                       address: AUParameterAddress(0),
                                                       min: 0.0, max: 200.0,
                                                       unit: .linearGain, unitName: nil,
                                                       flags: flags,
                                                       valueStrings: nil, dependentParameters: nil)
        let rightGain = AUParameterTree.createParameter(withIdentifier: "rightOffset",
                                                        name: "Right Offset Amount",
                                                        address: AUParameterAddress(1),
                                                        min: 0.0, max: 200.0,
                                                        unit: .linearGain, unitName: nil,
                                                        flags: flags,
                                                        valueStrings: nil, dependentParameters: nil)
        setParameterTree(AUParameterTree.createTree(withChildren: [leftGain, rightGain]))
        leftGain.value = 1.0
        rightGain.value = 1.0
    }

    public override var canProcessInPlace: Bool { return true }

}
