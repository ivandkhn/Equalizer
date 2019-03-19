//
//  FFTView.swift
//  Equalizer
//
//  Created by Иван Дахненко on 26/02/2019.
//  Copyright © 2019 Ivan Dakhnenko. All rights reserved.
//

import Cocoa

class FFTView: NSView {
    
    var dataToDraw = [Float](repeating: -20, count: 512)
    
    var bufferLength = 20 //store last n FFT results
    var currentBufferIndex = 0
    var lastFFTResults = [[Float]()]
    
    
    var zoomFactor: Float = 2
    var lowDBGainOffset: Float = 80
    var width = 0, height = 0
    let ignoreValuesCount = 200
    
    func modifyFFTResults(newData: [Float]) {
        if lastFFTResults.count < bufferLength {
            lastFFTResults.append(newData)
        } else {
            lastFFTResults[currentBufferIndex] = newData
            currentBufferIndex += 1
            if currentBufferIndex >= bufferLength {
                currentBufferIndex = 0
            }
        }
        computeAverage()
    }
    
    fileprivate func computeAverage() {
        var tempSum: Float = 0;
        for index in dataToDraw.indices {
            tempSum = 0
            for j in 0..<bufferLength {
                if j>=lastFFTResults.count || lastFFTResults[j].count == 0 {
                    continue
                }
                tempSum += lastFFTResults[j][index]
            }
            dataToDraw[index] = tempSum / Float(bufferLength)
        }
    }

    /// Given float variables in [data] array,
    /// fits and strokes all the values according to the view boundaries.
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        width = Int(self.frame.width)
        height = Int(self.frame.height)

        guard let context = NSGraphicsContext.current?.cgContext else {return}
        context.setStrokeColor(CGColor.black)
        context.setFillColor(CGColor.black)
        context.setLineWidth(CGFloat(3))
        
        var xComputed, yComputed: Int
        if (dataToDraw.count > 0) {
            let firstPointYCoord = Int(dataToDraw[0])
            context.move(to: CGPoint(x: 0, y: firstPointYCoord))
            for i in dataToDraw.indices.dropLast(ignoreValuesCount).dropFirst() {
                xComputed = Int(
                    Float(i) * Float(width) / Float(dataToDraw.count-ignoreValuesCount)
                )
                yComputed = Int(dataToDraw[i] * zoomFactor + lowDBGainOffset)
                let point = CGPoint(x: xComputed, y: yComputed)
                context.addLine(to: point)
            }
            
            // adding lines to the beginning of the path
            // to have a smooth line in the bottom of spectrum.
            context.addLine(to: CGPoint(x: width, y: 0))
            context.addLine(to: CGPoint(x: 0, y: 0))
            context.addLine(to: CGPoint(x: 0, y: firstPointYCoord))
            context.drawPath(using: .fill)
        }

    }
}
