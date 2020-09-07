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
    private let frames: Int = 50
    private var invalids: [CGPoint : Double] = [:]
    
    required init(level: LevelView) {
        self.level = level
    }
    
    func build(from transform: Transform, state: Int) -> [DrawItem] {
        //Evolve phase
        switch level.state {
        case .MOTION(let queue):
            return generate(from: queue, test: level.input.getTest(), state: state)
        case .REST:
            if let path = level.input.getTest() {
                return generate(from: [], test: path, state: state)
            }
            else {
                return generateInvalids(from: ProjectionHandler.compress(vertex: level.position, onto: level.plane).flatten(), state: state)
            }
        default:
            return []
        }
    }
    
    func registerInvalid(at point: CGPoint) {
        invalids[point] = 1.0
    }
    
    private func generateInvalids(from position: CGPoint, state: Int) -> [DrawItem] {
        var items: [DrawItem] = []
        
        for fail in invalids.keys {
            let color: CGColor = .init(srgbRed: 1, green: 0, blue: 0, alpha: CGFloat(invalids[fail]!))
            items.append(.LINE(position, fail, color, 2))
            items.append(fauxPlayer(at: fail, in: color, state: state))
            if let intensity = invalids[fail], intensity > 0 {
                invalids[fail] = intensity - 0.02
            }
            else {
                invalids.removeValue(forKey: fail)
            }
        }
        return items
    }
    
    private func fauxPlayer(at position: CGPoint, in color: CGColor, state: Int) -> DrawItem {
        let base = 10.0
        let variation = 0.5
        let rounds = 3
        let points = 8
        let speed = 8.0
        let path: CGMutablePath = CGMutablePath()
        func place(_ arc: Double) -> CGPoint {
            let x = cos(arc) * (base + variation * sin(Double(rounds) * arc + Double(state) / speed))
            let y = sin(arc) * (base + variation * sin(Double(rounds) * arc - Double(state) / speed))
            return CGPoint(x: CGFloat(x) + position.x, y: CGFloat(y) + position.y)
        }
        let initial = place(0)
        path.move(to: initial)
        var history: [CGPoint] = [initial]
        for i in 1 ..< points * rounds {
            let arc = Double(i) / Double(points * rounds) * 3.14159 * 2.0
            history.append(place(arc))
        }
        history.append(initial)
        path.addLines(between: history)
        path.closeSubpath()
        return DrawItem.PATH(path, color, 3)
    }
    
    private func generate(from queue: [CGPoint], test: CGPoint?, state: Int) -> [DrawItem] {
        let phase = CGFloat(state % frames) / CGFloat(frames)
        let start = (state - 1) % (frames * 2) >= frames
        let length: CGFloat = 50
        let offset: CGFloat = phase * length
        //Build path
        let position = ProjectionHandler.compress(vertex: level.position, onto: level.plane).flatten()
        var path: [CGPoint] = [position]
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
        var items: [DrawItem] = generateInvalids(from: path.last ?? position, state: state)
        
        var reds: [Line] = []
        if test != nil {
            if let contact = level.contact.findContact(from: path.last!, to: test!) {
                blacks.append(contentsOf: dotline(from: path.last!, to: contact))
                reds.append(contentsOf: dotline(from: contact, to: test!))
                let color: CGColor = .init(srgbRed: 1, green: 0, blue: 0, alpha: 0.5)
                items.append(fauxPlayer(at: contact, in: color, state: state))
                items.append(fauxPlayer(at: test!, in: color, state: state))
            }
            else {
                blacks.append(contentsOf: dotline(from: path.last!, to: test!))
                let color: CGColor = .init(srgbRed: 0, green: 0, blue: 0, alpha: 0.5)
                items.append(fauxPlayer(at: test!, in: color, state: state))
            }
        }
        else {
            let color: CGColor = .init(srgbRed: 0, green: 0, blue: 0, alpha: 0.5)
            items.append(fauxPlayer(at: path.last!, in: color, state: state))
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
