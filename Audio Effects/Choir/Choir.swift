//
//  Choir.swift
//  Equalizer
//
//  Created by Иван Дахненко on 05/03/2019.
//  Copyright © 2019 Ivan Dakhnenko. All rights reserved.
//

import AudioKit

open class Choir: AKNode, AKToggleable, AKComponent, AKInput {
    public typealias AKAudioUnitType = ChoirAudioUnit
    public static let ComponentDescription = AudioComponentDescription(effect: "chir")
    private var internalAU: AKAudioUnitType?
    private var token: AUParameterObserverToken?

    fileprivate var leftGainParameter: AUParameter?
    fileprivate var rightGainParameter: AUParameter?

    @objc open dynamic var rampDuration: Double = AKSettings.rampDuration {
        willSet {
            internalAU?.rampDuration = newValue
        }
    }

    @objc open dynamic var rampType: AKSettings.RampType = .linear {
        willSet {
            internalAU?.rampType = newValue.rawValue
        }
    }

    fileprivate var lastKnownLeftGain: Double = 1.0
    fileprivate var lastKnownRightGain: Double = 1.0

    @objc open dynamic var gain: Double = 1 {
        willSet {
            if gain == newValue {
                return
            }
            if internalAU?.isSetUp ?? false {
                if let token = token {
                    leftGainParameter?.setValue(Float(newValue), originator: token)
                    rightGainParameter?.setValue(Float(newValue), originator: token)
                    return
                }
            }

            internalAU?.setParameterImmediately(.leftGain, value: newValue)
            internalAU?.setParameterImmediately(.rightGain, value: newValue)
        }
    }

    @objc open dynamic var leftGain: Double = 1 {
        willSet {
            if leftGain == newValue {
                return
            }
            if internalAU?.isSetUp ?? false {
                if let token = token {
                    leftGainParameter?.setValue(Float(newValue), originator: token)
                    return
                }
            }
            internalAU?.setParameterImmediately(.leftGain, value: newValue)
        }
    }

    @objc open dynamic var rightGain: Double = 1 {
        willSet {
            if rightGain == newValue {
                return
            }
            if internalAU?.isSetUp ?? false {
                if let token = token {
                    rightGainParameter?.setValue(Float(newValue), originator: token)
                    return
                }
            }
            internalAU?.setParameterImmediately(.rightGain, value: newValue)
        }
    }

    @objc open dynamic var dB: Double {
        set {
            self.gain = pow(10.0, Double(newValue / 20))
        }
        get {
            return 20.0 * log10(self.gain)
        }
    }

    @objc open dynamic var isStarted: Bool {
        return self.internalAU?.isPlaying ?? false
    }

    @objc public init(
        _ input: AKNode? = nil,
        gain: Double = 1
    ) {

        self.leftGain = gain
        self.rightGain = gain

        _Self.register()

        super.init()
        AVAudioUnit._instantiate(with: _Self.ComponentDescription) { [weak self] avAudioUnit in
            guard let strongSelf = self else {
                AKLog("Error: self is nil")
                return
            }
            strongSelf.avAudioUnit = avAudioUnit
            strongSelf.avAudioNode = avAudioUnit
            strongSelf.internalAU = avAudioUnit.auAudioUnit as? AKAudioUnitType

            input?.connect(to: strongSelf)
        }

        guard let tree = internalAU?.parameterTree else {
            AKLog("Parameter Tree Failed")
            return
        }

        self.leftGainParameter = tree["leftOffset"]
        self.rightGainParameter = tree["rightOffset"]

        self.token = tree.token(byAddingParameterObserver: { [weak self] _, _ in
            guard let _ = self else {
                AKLog("Unable to create strong reference to self")
                return
            }
        })
        self.internalAU?.setParameterImmediately(.leftGain, value: gain)
        self.internalAU?.setParameterImmediately(.rightGain, value: gain)
        self.internalAU?.setParameterImmediately(.rampDuration, value: self.rampDuration)
        self.internalAU?.rampType = self.rampType.rawValue
    }

    @objc open func start() {
        if isStopped {
            self.leftGain = lastKnownLeftGain
            self.rightGain = self.lastKnownRightGain
        }
    }
    
    @objc open func stop() {
        if isPlaying {
            self.lastKnownLeftGain = leftGain
            self.lastKnownRightGain = rightGain
            self.leftGain = 1
            self.rightGain = 1
        }
    }
}
