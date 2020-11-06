//
//  PlayerBuilder.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 6/17/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit

//Builder for the player element
class PlayerBuilder: Builder {
    //Supervisor
    unowned var level: LevelView
    private var loc: CGPoint = CGPoint(x: 0, y: 0)
    
    //Initializes from supervisor reference
    required init(level: LevelView) {
        self.level = level
    }
    
    //Builds the player element given the transition and current state
    func build(from transform: Transform, state: Int) -> [DrawItem] {
        //Retreive the current position and flatten
        let pos: CGPoint = transform(Polygon(vertices: [level.position])).vertices[0].flatten()
        loc = pos
        
        //Player visuals configuration
        let base = 10.0
        let variation = 0.5
        let rounds = 3
        let points = 8
        let speed = 8.0
        let path: CGMutablePath = CGMutablePath()
        
        //Equation for player shape with given state
        func place(_ arc: Double) -> CGPoint {
            let x = cos(arc) * (base + variation * sin(Double(rounds) * arc + Double(state) / speed))
            let y = sin(arc) * (base + variation * sin(Double(rounds) * arc - Double(state) / speed))
            return CGPoint(x: CGFloat(x) + pos.x, y: CGFloat(y) + pos.y)
        }
        
        //Iterate through angles to build player path
        let initial = place(0)
        path.move(to: initial)
        var history: [CGPoint] = [initial]
        for i in 1 ..< points * rounds {
            let arc = Double(i) / Double(points * rounds) * 3.14159 * 2.0
            history.append(place(arc))
        }
        history.append(initial)
        
        //Make path from calculated points
        path.addLines(between: history)
        path.closeSubpath()
        
        //Return path as a DrawItem
        return [DrawItem.PATH(path, .init(srgbRed: 0, green: 0, blue: 0, alpha: 1), 3)]
    }
    
    //Returns the last stored two dimensional player location
    func location() -> CGPoint {
        return loc
    }
}
