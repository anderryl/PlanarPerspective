//
//  RenderHandler.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 6/3/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit

//Delegate class for rendering the view with each frame
class RenderHandler {
    //Called before each frame with DrawItems and a context to draw them into
    func render(items: [DrawItem], context: CGContext?) {
        
        //Subfunction to add an item to a layer based on priority
        var layers: [Int : [DrawItem]] = [:]
        func append(item: DrawItem, at priority: Int) {
            if var layer = layers[priority] {
                layer.append(item)
                layers[priority] = layer
            }
            else {
                layers[priority] = [item]
            }
        }
        
        //Build layers based on priority
        for item in items {
            switch item {
            case .LINE(_, _, _, _, let layer):
                append(item: item, at: layer)
            case .CIRCLE(_, _, _, let layer):
                append(item: item, at: layer)
            case .RECTANGLE(_, _, _, let layer):
                append(item: item, at: layer)
            case .PATH(_, _, let layer):
                append(item: item, at: layer)
            }
        }
        
        //Iterates through priorities drawing higher priorities over lower ones
        for layer in layers.keys.sorted() {
            //Iterates through each item in a given layer
            for item in layers[layer]! {
                //Each item type is drawn according to its parameters
                switch item {
                case .LINE(let origin, let outpost, let color, let thickness, _):
                    context?.setStrokeColor(color)
                    context?.setLineCap(.round)
                    context?.setLineWidth(thickness)
                    context?.addLines(between: [origin, outpost])
                    context?.strokePath()
                case .CIRCLE(let position, let radius, let color, _):
                    context?.setFillColor(color)
                    context?.fillEllipse(in: CGRect(origin: CGPoint(x: position.x - radius, y: position.y - radius), size: CGSize(width: radius * 2, height: radius * 2)))
                case .RECTANGLE(let origin, let size, let color, _):
                    context?.setFillColor(color)
                    context?.fill(CGRect(origin: origin, size: size))
                case .PATH(let path, let color, _):
                    context?.addPath(path)
                    context?.setFillColor(color)
                    context?.fillPath()
                }
            }
        }
    }
}
