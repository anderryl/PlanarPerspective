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
class ContactHandler {
    //Supervisor
    private unowned let level: LevelView
    private let radius: CGFloat
    
    //Initializes delegate with reference to supervisor
    init(level: LevelView, radius: CGFloat) {
        self.level = level
        self.radius = radius
    }
    
    //Find contacts along player path with environment lines
    func findContact(from position: CGPoint, to point: CGPoint) -> CGPoint? {
        //Allocates empty array for collisions
        var contacts: [CGPoint] = []
        let player = Line(origin: position, outpost: point)
        //Compress the polygons onto the current plane
        let transform = ProjectionHandler.component(of: level.plane)
        let lines: [Line] = level.compression.compress(with: transform)
        //Iterate through lines and find collisions
        for line in lines {
            contacts.append(contentsOf: contact(between: line, and: player))
        }
        
        //Find soonest collision
        let closest = contacts.max(by: { $0 | player.origin > $1 | player.origin })
        
        //Return the closest
        if let best = closest, best | position < position | point {
            return best
        }
        
        //If no collisions, return nil
        return nil
    }
    
    //Finds contacts between the player line and an individual environment line
    private func contact(between line: Line, and player: Line) -> [CGPoint] {
        //Translate the line perpindicular to its own direction by one radius both ways
        let lmag = line.origin | line.outpost
        let lvecx = (line.outpost.x - line.origin.x) * radius / lmag
        let lvecy = (line.outpost.y - line.origin.y) * radius / lmag
        let translatedOne = Line(origin: CGPoint(x: line.origin.x - lvecy, y: line.origin.y + lvecx), outpost: CGPoint(x: line.outpost.x - lvecy, y: line.outpost.y + lvecx))
        let translatedTwo = Line(origin: CGPoint(x: line.origin.x + lvecy, y: line.origin.y - lvecx), outpost: CGPoint(x: line.outpost.x + lvecy, y: line.outpost.y - lvecx))
        
        //Allocate empty array for collisions
        var ret: [CGPoint] = []
        
        //Check translated lines against the player line and append any to the list
        if let intersection = intersection(between: translatedOne, and: player) {
            ret.append(intersection)
        }
        if let intersection = intersection(between: translatedTwo, and: player) {
            ret.append(intersection)
        }
        
        //Check player line against the environment line's endpoints
        ret.append(contentsOf: caps(of: line.origin, against: player))
        ret.append(contentsOf: caps(of: line.outpost, against: player))
        //Return the collisions
        return ret
    }
    
    //Finds the intersection between two lines
    private func intersection(between first: Line, and second: Line) -> CGPoint? {
        //Calculate line vector components
        let delta1x = first.outpost.x - first.origin.x
        let delta1y = first.outpost.y - first.origin.y
        let delta2x = second.outpost.x - second.origin.x
        let delta2y = second.outpost.y - second.origin.y

        //Create a 2D matrix from the vectors and calculate the determinant
        let determinant = delta1x * delta2y - delta2x * delta1y
        
        //If determinant is zero (or very close as approximation), the lines are parallel or colinear
        if abs(determinant) < 0.0001 {
            return nil
        }

        //If the coefficients are between 0 and 1 (meaning they occur between their beginnings and ends not off in the distance), there is an intersection
        let ab = ((first.origin.y - second.origin.y) * delta2x - (first.origin.x - second.origin.x) * delta2y) / determinant
        if ab > 0 && ab < 1 {
            let cd = ((first.origin.y - second.origin.y) * delta1x - (first.origin.x - second.origin.x) * delta1y) / determinant
            if cd > 0 && cd < 1 {
                //Calculate exact intersection point
                let intersectX = first.origin.x + ab * delta1x
                let intersectY = first.origin.y + ab * delta1y
                return CGPoint(x: intersectX, y: intersectY)
            }
        }
        
        //Lines don't cross
        return nil
    }
    
    //Finds the collisions between an endcap and the player line
    private func caps(of center: CGPoint, against player: Line) -> [CGPoint] {
        //Translate the player line so that the center of the endcap is the origin
        let line = Line(origin: CGPoint(x: player.origin.x - center.x, y: player.origin.y - center.y), outpost: CGPoint(x: player.outpost.x - center.x, y: player.outpost.y - center.y))
        
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
