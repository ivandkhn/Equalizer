//
//  FFTView.swift
//  Equalizer
//
//  Created by Иван Дахненко on 26/02/2019.
//  Copyright © 2019 Ivan Dakhnenko. All rights reserved.
//

import Cocoa

class FFTView: NSView {
    var data = [Float]()
    var zoomFactor: Float = 2
    var lowDBGainOffset: Float = 40
    var width = 0, height = 0
    let ignoreValuesCount = 200

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
        if (data.count > 0) {
            let firstPointYCoord = Int(data[0])
            context.move(to: CGPoint(x: 0, y: firstPointYCoord))
            for i in data.indices.dropLast(ignoreValuesCount).dropFirst() {
                xComputed = Int(
                    Float(i) * Float(width) / Float(data.count-ignoreValuesCount)
                )
                yComputed = Int(data[i] * zoomFactor + lowDBGainOffset)
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
