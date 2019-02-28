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

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let width = self.frame.width
        let height = self.frame.height

        guard let context = NSGraphicsContext.current?.cgContext else {return}
        context.setStrokeColor(CGColor.black)
        context.setFillColor(CGColor.black)
        context.setLineWidth(CGFloat(3))
        
        if (data.count > 0) {
            let firstPointYCoord = Int(data[0])
            context.move(to: CGPoint(x: 0, y: firstPointYCoord))
            for i in data.indices {
                let point = CGPoint(x: Int(Float(i)*Float(width)/Float(data.count)),
                                    y: Int(data[i] * zoomFactor + lowDBGainOffset))
                context.addLine(to: point)
            }
            context.addLine(to: CGPoint(x: width, y: 0))
            context.addLine(to: CGPoint(x: 0, y: 0))
            context.addLine(to: CGPoint(x: 0, y: firstPointYCoord))
            context.drawPath(using: .fill)
        }

    }
}
