//
//  RenderHandler.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 6/3/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit

class RenderHandler {
    func render(items: [DrawItem], context: CGContext?) {
        var lines: [DrawItem] = []
        var rectangles: [DrawItem] = []
        var circles: [DrawItem] = []
        var paths: [DrawItem] = []
        for item in items {
            switch item {
            case .LINE(_):
                lines.append(item)
                /*context?.addLines(between: [origin, outpost])
                context?.setStrokeColor(color)
                context?.setLineCap(.round)
                context?.setLineWidth(2)
                context?.strokePath()*/
            case .CIRCLE(_):
                circles.append(item)
                /*context?.setFillColor(color)
                context?.fillEllipse(in: CGRect(origin: CGPoint(x: position.x - radius, y: position.y - radius), size: CGSize(width: radius * 2, height: radius * 2)))*/
            case .RECTANGLE(_):
                rectangles.append(item)
                /*context?.setFillColor(color)
                context?.fill(CGRect(origin: origin, size: size))*/
            case .PATH(_):
                paths.append(item)
            }
        }
        
        for line in lines {
            switch line {
            case .LINE(let origin, let outpost, let color):
                context?.addLines(between: [origin, outpost])
                context?.setStrokeColor(color)
                context?.setLineCap(.round)
                context?.setLineWidth(2)
                context?.strokePath()
                
            default:
                continue
            }
        }
        for circle in circles {
            switch circle {
            case .CIRCLE(let position, let radius, let color):
                context?.setFillColor(color)
                context?.fillEllipse(in: CGRect(origin: CGPoint(x: position.x - radius, y: position.y - radius), size: CGSize(width: radius * 2, height: radius * 2)))
                
            default:
                continue
            }
        }
        
        for rectangle in rectangles {
            switch rectangle {
            case .RECTANGLE(let origin, let size, let color):
                context?.setFillColor(color)
                context?.fill(CGRect(origin: origin, size: size))
                
            default:
                continue
            }
        }
        
        for path in paths {
            switch path {
            case .PATH(let path, let color):
                context?.addPath(path)
                context?.setFillColor(color)
                context?.fillPath()
            default:
                continue
            }
        }
    }
}
