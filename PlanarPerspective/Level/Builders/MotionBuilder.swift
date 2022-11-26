//
//  MotionBuilder.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 6/13/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit

//Builder for visual motion effects
class MotionBuilder: Builder {
    //Length of motion
    private let frames: Int = 50
    
    //Builds motion elements using given transform and state
    func build(from snapshot: BuildSnapshot) -> [DrawItem] {
        return generate(from: snapshot.queue, position: snapshot.position, test: snapshot.test, scale: snapshot.scale, state: snapshot.state, invalids: snapshot.invalids)
    }
    
    //Render the invalid movement attempts
    private func generateInvalids(from position: CGPoint, scale: CGFloat, state: Int, invalids: [CompressedInvalid]) -> [DrawItem] {
        //Allocate empty list for items
        var items: [DrawItem] = []
        
        //Build each individual invalid and append to list
        for invalid in invalids {
            //Add a faux player at the endpoint and a line between the origin and outpost
            let color: CGColor = .init(srgbRed: 1, green: 0, blue: 0, alpha: CGFloat(invalid.intensity))
            items.append(.LINE(invalid.origin, invalid.outpost, color, 1.0, 2))
            items.append(fauxPlayer(at: invalid.outpost, in: color, scale: scale, state: state))
        }
        
        //Return completed list
        return items
    }
    
    //Builds a faux player based on state at the specified position
    private func fauxPlayer(at position: CGPoint, in color: CGColor, scale: CGFloat, state: Int) -> DrawItem {
        //Player visuals configuration
        let base = 10.0 * scale
        let variation = 0.5
        let rounds = 3
        let points = 8
        let speed = 8.0
        let path: CGMutablePath = CGMutablePath()
        
        //Equation for player shape at given time
        func place(_ arc: Double) -> CGPoint {
            let x = cos(arc) * (base + variation * sin(Double(rounds) * arc + Double(state) / speed))
            let y = sin(arc) * (base + variation * sin(Double(rounds) * arc - Double(state) / speed))
            return CGPoint(x: CGFloat(x) + position.x, y: CGFloat(y) + position.y)
        }
        
        //Build player path from equation by iterating through angles
        let initial = place(0)
        path.move(to: initial)
        var history: [CGPoint] = [initial]
        for i in 1 ..< points * rounds {
            let arc = Double(i) / Double(points * rounds) * 3.14159 * 2.0
            history.append(place(arc))
        }
        history.append(initial)
        
        //Create path from the points
        path.addLines(between: history)
        path.closeSubpath()
        
        //Return the path as a DrawItem
        return DrawItem.PATH(path, color, 3)
    }
    
    //Generate the full motion effect given the queue and test point
    private func generate(from queue: [CGPoint], position: CGPoint, test: Test?, scale: CGFloat, state: Int, invalids: [CompressedInvalid]) -> [DrawItem] {
        //The current visual phase based on state
        let phase = CGFloat(state % frames) / CGFloat(frames)
        
        //Initial visibility
        let start = (state - 1) % (frames * 2) >= frames
        
        //The length of each line
        let length: CGFloat = 50
        
        //The current start offset based on state
        let offset: CGFloat = phase * length
        
        //Build path
        var path: [CGPoint] = [position]
        path.append(contentsOf: queue)
        
        //Tally up distance
        var dist: CGFloat = 0
        for i in 0 ..< path.count - 1 {
            dist += path[i] | path[i + 1]
        }
        if let concrete = test {
            dist += path.last! | concrete.point
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
        
        //Allocate list to store black lines
        var blacklines: [Line] = []
        
        //The running total of distance processed
        var running: CGFloat = 0
        var visible: Bool = start
        
        //Builds a dotted line between two points
        func dotline(from origin: CGPoint, to outpost: CGPoint) -> [Line] {
            //Calculates vector components of line
            let dx = outpost.x - origin.x
            let dy = outpost.y - origin.y
            
            //Length of line
            let segment = origin | outpost
            
            //Finds only the ticks within the bounds of the line
            let applicable = ticks.filter { $0 > running && $0 < segment + running }
            
            //Builds lines between each applicable tickmark
            var segments: [Line] = []
            var along = applicable.map { (tick: CGFloat) in
                return CGPoint(x: dx * ((tick - running) / segment) + origin.x, y: dy * ((tick - running) / segment) + origin.y)
            }
            
            //Inserts the line's origin as beginning of list
            along.insert(origin, at: 0)
            
            //Adds every other line to render list
            for i in 0 ..< along.count - 1 {
                if visible {
                    segments.append(Line(origin: along[i], outpost: along[i + 1]))
                }
                visible = !visible
            }
            
            //If the last segment will be visible, add a line between the final tickmark and the line's outpost
            if visible {
                segments.append(Line(origin: along.last!, outpost: outpost))
            }
            
            //Add the segments length to the running count
            running += segment
            
            //Return the visible segments
            return segments
        }
        
        //Build regular path
        for i in 0 ..< path.count - 1 {
            blacklines.append(contentsOf: dotline(from: path[i], to: path[i + 1]))
        }
        
        //Build test path
        //Compile DrawItems in both colors
        var items: [DrawItem] = generateInvalids(from: path.last ?? position, scale: scale, state: state, invalids: invalids)
        
        //Allocate list to store red lines
        var redlines: [Line] = []
        
        //If there is a test, process it
        if let concrete = test {
            //If there is a contact, build a legitimate line to the contact, a legitimate faux player at it, an invalid from the contact to the destination, and an invalid faux player at the destination
            if !concrete.valid {
                blacklines.append(contentsOf: dotline(from: path.last!, to: concrete.intersect!))
                redlines.append(contentsOf: dotline(from: concrete.intersect!, to: concrete.point))
                let color: CGColor = .init(srgbRed: 1, green: 0, blue: 0, alpha: 0.5)
                items.append(fauxPlayer(at: concrete.intersect!, in: color, scale: scale, state: state))
                items.append(fauxPlayer(at: concrete.point, in: color, scale: scale, state: state))
            }
            //If there is no contact, build legitimate line to outpost and a legitimate faux player at it
            else {
                blacklines.append(contentsOf: dotline(from: path.last!, to: concrete.point))
                let color: CGColor = .init(srgbRed: 0, green: 0, blue: 0, alpha: 0.5)
                items.append(fauxPlayer(at: concrete.point, in: color, scale: scale, state: state))
            }
        }
        //If there is no test, build a faux player at the final destination
        else {
            let color: CGColor = .init(srgbRed: 0, green: 0, blue: 0, alpha: 0.5)
            items.append(fauxPlayer(at: path.last!, in: color, scale: scale, state: state))
        }
        
        //Build the draw items depending on color
        for line in blacklines {
            items.append(.LINE(line.origin, line.outpost, .init(srgbRed: 0, green: 0, blue: 0, alpha: 1), 1.0, 2))
        }
        for line in redlines {
            items.append(.LINE(line.origin, line.outpost, .init(srgbRed: 1, green: 0, blue: 0, alpha: 1), 1.0, 2))
        }
        
        //Return the final results
        return items
    }
}
