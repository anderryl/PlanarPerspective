//
//  Tangent.swift
//  PlanarPerspective
//
//  Created by Rylie Anderson on 1/28/23.
//  Copyright © 2023 Anderson, Todd W. All rights reserved.
//

import Foundation

infix operator ^^

struct Tangent {
    var origin: CGPoint
    var outpost: CGPoint
    var start: CGFloat
    var end: CGFloat
    
    var bounds: CGRect {
        let offset = outpost - origin
        return CGRect(origin: origin, size: CGSize(width: offset.x, height: offset.y))
    }
    
    func harden() -> MetalTangent {
        return MetalTangent(origin: simd_float2(x: Float(origin.x), y: Float(origin.y)), outpost: simd_float2(x: Float(outpost.x), y: Float(outpost.y)), start: Float(start), end: Float(end))
    }
    
    static func ^^(_ first: Tangent, _ second: Tangent) -> CGPoint? {
        guard first.bounds.intersects(second.bounds) else {
            return nil
        }
        
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
