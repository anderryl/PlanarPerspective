//
//  MotionBuilder.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 6/13/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit

class MotionBuilder: Builder {
    var level: LevelView
    private var phase: CGFloat = 0
    private var start: Bool = true
    private let rate: CGFloat = 0.02
    
    required init(level: LevelView) {
        self.level = level
    }
    
    func build(from transform: Transform) -> [DrawItem] {
        //Evolve phase
        phase += rate
        if phase >= 1.0 {
            phase = rate
            start = !start
        }
        switch level.state {
        case .MOTION(let queue):
            return generate(from: queue, test: level.input.getTest())
        case .REST:
            if let path = level.input.getTest() {
                return generate(from: [], test: path)
            }
            else {
                return []
            }
        default:
            return []
        }
    }
    
    private func generate(from queue: [CGPoint], test: CGPoint?) -> [DrawItem] {
        let length: CGFloat = 50
        let offset: CGFloat = phase * length
        //Build path
        var path: [CGPoint] = [ProjectionHandler.compress(vertex: level.position, onto: level.plane).flatten()]
        path.append(contentsOf: queue)
        //Tally up distance
        var dist: CGFloat = 0
        for i in 0 ..< path.count - 1 {
            dist += path[i] | path[i + 1]
        }
        if test != nil {
            dist += path.last! | test!
        }
        //Place ticks forward of offset
        var ticks: [CGFloat] = []
        var i: CGFloat = offset
        while i < dist {
            if i > 0 {
                ticks.append(i)
            }
            i += length
        }
        //Place ticks backwards of offset
        i = offset
        i -= length
        while i > 0 {
            if i < dist {
                ticks.append(i)
            }
            i -= length
        }
        
        //Build lines
        var blacks: [Line] = []
        var running: CGFloat = 0
        var visible: Bool = start
        
        //Builds a dotted line between two points
        func dotline(from origin: CGPoint, to outpost: CGPoint) -> [Line] {
            let dx = outpost.x - origin.x
            let dy = outpost.y - origin.y
            let segment = origin | outpost
            let applicable = ticks.filter { $0 > running && $0 < segment + running }
            var segments: [Line] = []
            var along = applicable.map { (tick: CGFloat) in
                return CGPoint(x: dx * ((tick - running) / segment) + origin.x, y: dy * ((tick - running) / segment) + origin.y)
            }
            along.insert(origin, at: 0)
            for i in 0 ..< along.count - 1 {
                if visible {
                    segments.append(Line(origin: along[i], outpost: along[i + 1]))
                }
                visible = !visible
            }
            if visible {
                segments.append(Line(origin: along.last!, outpost: outpost))
            }
            running += segment
            return segments
        }
        //Build regular path
        for i in 0 ..< path.count - 1 {
            blacks.append(contentsOf: dotline(from: path[i], to: path[i + 1]))
        }
        
        //Build test path
        //Compile DrawItems in both colors
        var items: [DrawItem] = []
        var reds: [Line] = []
        if test != nil {
            if let contact = level.contact.findContact(from: path.last!, to: test!) {
                blacks.append(contentsOf: dotline(from: path.last!, to: contact))
                reds.append(contentsOf: dotline(from: contact, to: test!))
                items.append(.CIRCLE(contact, 10, .init(srgbRed: 1, green: 0, blue: 0, alpha: 0.5), 3))
                items.append(.CIRCLE(test!, 10, .init(srgbRed: 1, green: 0, blue: 0, alpha: 0.5), 3))
            }
            else {
                blacks.append(contentsOf: dotline(from: path.last!, to: test!))
                items.append(.CIRCLE(test!, 10, .init(srgbRed: 0, green: 0, blue: 0, alpha: 0.5), 3))
            }
        }
        else {
            items.append(.CIRCLE(queue.last!, 10, .init(srgbRed: 0, green: 0, blue: 0, alpha: 0.5), 3))
        }
        for line in blacks {
            items.append(.LINE(line.origin, line.outpost, .init(srgbRed: 0, green: 0, blue: 0, alpha: 1), 2))
        }
        for line in reds {
            items.append(.LINE(line.origin, line.outpost, .init(srgbRed: 1, green: 0, blue: 0, alpha: 1), 2))
        }
        return items
    }
}
