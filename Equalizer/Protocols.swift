//
//  Protocols.swift
//  Equalizer
//
//  Created by Иван Дахненко on 27.12.2018.
//  Copyright © 2018 Ivan Dakhnenko. All rights reserved.
//

import Foundation

/// Class conforming this protocol can process audio data.
class AbstractAudioProcessor {
    var windowSize: UInt = 1024
    
    var buffer: [AudioDataChunk] = [AudioDataChunk()]
    
    func process(initialData: AudioDataChunk, wetLevel: Double) -> AudioDataChunk {
        return initialData
    }
    
}

protocol DescriptonProviding {
    var description: String {get}
}


// MARK: remove following classes in different .swift file
class AudioDataChunk {
    var values: [Int] {
        didSet {
            length = values.count
        }
    }
    
    var length: Int
    
    init(data: [Int]) {
        values = data
        length = values.count
    }
    
    init() {
        values = []
        length = values.count
    }
}


class testAudioEffect: AbstractAudioProcessor, DescriptonProviding {
    let description = "TEST1"
}

class testAudioEffect2: AbstractAudioProcessor, DescriptonProviding {
    let description = "TEST2"
}

//for i in [testAudioEffect(), testAudioEffect2()] {
//    let i = i as! DescriptonProviding
//    print(i.description)
//}
