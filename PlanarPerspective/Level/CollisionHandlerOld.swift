//
//  ContactHandler.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 6/19/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit

//Utility delegate used to find collisions between player and environment
class CollisionHandlerOld {
    //Supervisor
    private unowned let level: LevelView
    private let radius: CGFloat
    
    //Initializes delegate with reference to supervisor
    init(level: LevelView, radius: CGFloat) {
        self.level = level
        self.radius = radius
    }
    
    //Find contacts along player path with environment lines
    func findContact(from position: Position, to point: Position) -> Position? {
        let transform = level.matrix
        //Allocates empty array for collisions
        var contacts: [CGPoint] = []
        let start = (transform * position).flatten()
        let end = (transform * point).flatten()
        let player = Arc(origin: start, outpost: end, control: (start + end) / 2)
        //Compress the polygons onto the current plane
        let lines: [Arc] = level.arcs
        //Iterate through lines and find collisions
        for line in lines {
            contacts.append(contentsOf: contact(between: line, and: player))
        }
        
        for line in level.region.flatten(transform: transform).arcs() {
            contacts.append(contentsOf: contact(between: line, and: player))
        }
        
        //Find soonest collision
        let closest = contacts.max(by: { $0 | player.origin > $1 | player.origin })
        
        //Return the closest
        if let best = closest, best | player.origin < player.origin | player.outpost {
            return (transform.inverted() * Position(x: best.x, y: best.y, z: (level.matrix * position).z))
        }
        
        //If no collisions, return nil
        return nil
    }
    
    //Finds contacts between the player line and an individual environment line
    private func contact(between line: Arc, and player: Arc) -> [CGPoint] {
        if (line.origin == line.control && line.control == line.outpost) {
            return []
        }
        
        let left = line.normal(positive: true, radius: radius)
        
        let right = line.normal(positive: false, radius: radius)
        
        //Allocate empty array for collisions
        var ret: [CGPoint] = []
        
        
        //Check translated lines against the player line and append any to the list
        if let intersection = player ^^ left {
            ret.append(intersection)
        }
        
        if let intersection = player ^^ right {
            ret.append(intersection)
        }
        
        
        
        //Check player line against the environment line's endpoints
        ret.append(contentsOf: caps(of: line.origin, against: player))
        ret.append(contentsOf: caps(of: line.outpost, against: player))
        //Return the collisions
        return ret
    }
    
    //Finds the collisions between an endcap and the player line
    private func caps(of center: CGPoint, against player: Arc) -> [CGPoint] {
        //Translate the player line so that the center of the endcap is the origin
        let line = Arc(origin: CGPoint(x: player.origin.x - center.x, y: player.origin.y - center.y), outpost: CGPoint(x: player.outpost.x - center.x, y: player.outpost.y - center.y), thickness: 0)
        
        //Calculate player line vector components
        let dx = line.outpost.x - line.origin.x
        let dy = line.outpost.y - line.origin.y
        
        //Find the distance squared
        let dr2 = pow(dx, 2) + pow(dy, 2)
        let d = line.origin.x * line.outpost.y - line.outpost.x * line.origin.y
        let determinant = pow(radius, 2) * dr2 - pow(d, 2)
        
        //If discriminant is greater than zero, there may be a collision
        if determinant > 0 {
            
            func sign(_ float: CGFloat) -> CGFloat {
                if float.sign == .minus {
                    return -1.0
                }
                else {
                    return 1.0
                }
            }
            
            //Finds the potential collision points of the player line
            let x1 = (d * dy + sign(dy) * dx * sqrt(determinant)) / dr2
            let x2 = (d * dy - sign(dy) * dx * sqrt(determinant)) / dr2
            let y1 = (-d * dx + abs(dy) * sqrt(determinant)) / dr2
            let y2 = (-d * dx - abs(dy) * sqrt(determinant)) / dr2
            
            //Allocate empty list for collisions
            var ret: [CGPoint] = []
            
            //If the collision is on the line, add to the list
            if min(line.origin.x, line.outpost.x) <= x1 && max(line.origin.x, line.outpost.x) >= x1 {
                if min(line.origin.y, line.outpost.y) <= y1 && max(line.origin.y, line.outpost.y) >= y1 {
                    ret.append(CGPoint(x: x1 + center.x, y: y1 + center.y))
                }
            }
            if min(line.origin.x, line.outpost.x) <= x2 && max(line.origin.x, line.outpost.x) >= x2 {
                if min(line.origin.y, line.outpost.y) <= y2 && max(line.origin.y, line.outpost.y) >= y2 {
                    ret.append(CGPoint(x: x2 + center.x, y: y2 + center.y))
                }
            }
            
            //Return the list of collisions
            return ret
        }
        //If no potential collisions, return an empty list
        return []
    }
}
