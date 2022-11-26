//
//  Line.swift
//  PlanarPerspective
//
//  Created by Rylie Anderson on 11/25/22.
//  Copyright © 2022 Anderson, Todd W. All rights reserved.
//

import Foundation
import CoreGraphics

struct Line {
    var origin: CGPoint
    var outpost: CGPoint
    var intensity: CGFloat = 1.0
    var thickness: CGFloat = 1.0
    
    init(origin: CGPoint, outpost: CGPoint) {
        self.origin = origin
        self.outpost = outpost
    }
    
    init(origin: CGPoint, outpost: CGPoint, intensity: CGFloat, thickness: CGFloat) {
        self.origin = origin
        self.outpost = outpost
        self.intensity = intensity
        self.thickness = thickness
    }
    
    init(_ metal: MetalSegment) {
        self.origin = Vertex(metal.origin).flatten()
        self.outpost = Vertex(metal.outpost).flatten()
    }
    
    func softened() -> Line {
        return Line(origin: origin, outpost: outpost, intensity: 0.3, thickness: 5.0)
    }
    
    //Finds the intersection between two lines
    static func &(first: Line, second: Line) -> CGPoint? {
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
}
