//
//  AudioFilter.swift
//  Equalizer
//
//  Created by Иван Дахненко on 11/02/2019.
//  Copyright © 2019 Ivan Dakhnenko. All rights reserved.
//

import Foundation
import AudioKit

/*
 (0, 100)
 (100, 300)
 (300, 700)
 (700, 1500)
 (1500, 3100)
 (3100, 6300)
 (6300, 12700)
 (12700, 25500)
*/

var initialEqualizerBands: [Double] = [100, 300, 700, 1500, 3100, 6300, 12700]
var bandsAmount = initialEqualizerBands.count + 1

struct Effect {
    var name = ""
    var isToggledOn = false
    var level = 1.0
}


//
//
//
class Filter {
    func createFilterInstance(_ input: AKNode?, type: String, cutoff: Double) -> AKNode {
        switch type {
        case "lp":
            return AKLowPassFilter(input, cutoffFrequency: cutoff)
        case "hp":
            return AKHighPassFilter(input, cutoffFrequency: cutoff)
        default:
            toConsole("Couldn't create LP or HP filter")
        }
        return AKHighPassFilter(input, cutoffFrequency: cutoff)
    }
}

extension AKLowPassFilter {
    func changeParamater() {
        
    }
}
