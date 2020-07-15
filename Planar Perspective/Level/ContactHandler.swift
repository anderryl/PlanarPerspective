//
//  ContactHandler.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 6/19/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit

class ContactHandler {
    private unowned let level: LevelView
    private let radius: CGFloat
    
    init(level: LevelView, radius: CGFloat) {
        self.level = level
        self.radius = radius
    }
    
    func findContact(from position: CGPoint, to point: CGPoint) -> CGPoint? {
        var contacts: [CGPoint] = []
        let player = Line(origin: position, outpost: point)
        var lines: [Line] = []
        let transform = ProjectionHandler.component(of: level.plane)
        for polygon in level.polygons {
            let flat = transform(polygon)
            lines.append(contentsOf: flat.lines())
        }
        for line in lines {
            contacts.append(contentsOf: contact(between: line, and: player))
        }
        let closest = contacts.max(by: { $0 | player.origin > $1 | player.origin })
        if let best = closest, best | position < position | point {
            return best
        }
        return nil
    }
    
    private func contact(between line: Line, and player: Line) -> [CGPoint] {
        //Translate the line perpindicular to its own direction by one radius
        let lmag = line.origin | line.outpost
        let lvecx = (line.outpost.x - line.origin.x) * radius / lmag
        let lvecy = (line.outpost.y - line.origin.y) * radius / lmag
        let translatedOne = Line(origin: CGPoint(x: line.origin.x - lvecy, y: line.origin.y + lvecx), outpost: CGPoint(x: line.outpost.x - lvecy, y: line.outpost.y + lvecx))
        let translatedTwo = Line(origin: CGPoint(x: line.origin.x + lvecy, y: line.origin.y - lvecx), outpost: CGPoint(x: line.outpost.x + lvecy, y: line.outpost.y - lvecx))
        var ret: [CGPoint] = []
        //Check translated lines against the player line
        if let intersection = intersection(between: translatedOne, and: player) {
            ret.append(intersection)
        }
        if let intersection = intersection(between: translatedTwo, and: player) {
            ret.append(intersection)
        }
        //Check player line against line endpoints
        ret.append(contentsOf: caps(of: line.origin, against: player))
        ret.append(contentsOf: caps(of: line.outpost, against: player))
        return ret
    }
    
    /*
     Finds the intersection between two lines
     */
    private func intersection(between first: Line, and second: Line) -> CGPoint? {
        //Calculate the differences between the start and end X/Y positions for each of the points
        let delta1x = first.outpost.x - first.origin.x
        let delta1y = first.outpost.y - first.origin.y
        let delta2x = second.outpost.x - second.origin.x
        let delta2y = second.outpost.y - second.origin.y

        // create a 2D matrix from the vectors and calculate the determinant
        let determinant = delta1x * delta2y - delta2x * delta1y

        if abs(determinant) < 0.0001 {
            return nil
        }

        //If the coefficients are between 0 and 1, there is an intersection
        let ab = ((first.origin.y - second.origin.y) * delta2x - (first.origin.x - second.origin.x) * delta2y) / determinant
        if ab > 0 && ab < 1 {
            let cd = ((first.origin.y - second.origin.y) * delta1x - (first.origin.x - second.origin.x) * delta1y) / determinant
            if cd > 0 && cd < 1 {
                //Lines cross, so figure out where
                let intersectX = first.origin.x + ab * delta1x
                let intersectY = first.origin.y + ab * delta1y
                return CGPoint(x: intersectX, y: intersectY)
            }
        }
        
        //Lines don't cross
        return nil
    }
    
    private func caps(of center: CGPoint, against player: Line) -> [CGPoint] {
        let line = Line(origin: CGPoint(x: player.origin.x - center.x, y: player.origin.y - center.y), outpost: CGPoint(x: player.outpost.x - center.x, y: player.outpost.y - center.y))
        let dx = line.outpost.x - line.origin.x
        let dy = line.outpost.y - line.origin.y
        let dr2 = pow(dx, 2) + pow(dy, 2)
        let d = line.origin.x * line.outpost.y - line.outpost.x * line.origin.y
        let discriminant = pow(radius, 2) * dr2 - pow(d, 2)
        if discriminant > 0 {
            func sign(_ float: CGFloat) -> CGFloat {
                if float.sign == .minus {
                    return -1.0
                }
                else {
                    return 1.0
                }
            }
            let x1 = (d * dy + sign(dy) * dx * sqrt(discriminant)) / dr2
            let x2 = (d * dy - sign(dy) * dx * sqrt(discriminant)) / dr2
            let y1 = (-d * dx + abs(dy) * sqrt(discriminant)) / dr2
            let y2 = (-d * dx - abs(dy) * sqrt(discriminant)) / dr2
            var ret: [CGPoint] = []
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
            return ret
        }
        return []
    }
}
