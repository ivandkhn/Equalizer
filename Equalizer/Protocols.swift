//
//  Protocols.swift
//  Equalizer
//
//  Created by Иван Дахненко on 27.12.2018.
//  Copyright © 2018 Ivan Dakhnenko. All rights reserved.
//

import Foundation

/// Class conforming this protocol can process audio data.
protocol AudioDataProcessable {
    static var description: String {get}
    
    var windowSize: UInt {get set}
    
    var buffer: [AudioDataChunk] {get set}
    
    init(newWindowSize: UInt)
    
    func process(data: AudioDataChunk, wetLevel: Double) -> AudioDataChunk
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
}


class testAudioEffect: AudioDataProcessable {
    static var description = """
        Test audio effect description.
    """
    
    var description: String
    
    var windowSize: UInt
    
    var buffer: [AudioDataChunk]
    
    required init(newWindowSize: UInt) {
        <#code#>
    }
    
    func process(data: AudioDataChunk, wetLevel: Double) -> AudioDataChunk {
        <#code#>
    }
}
