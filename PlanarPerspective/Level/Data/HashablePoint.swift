//
//  HashablePoint.swift
//  PlanarPerspective
//
//  Created by Rylie Anderson on 11/25/22.
//  Copyright © 2022 Anderson, Todd W. All rights reserved.
//

import Foundation
import CoreGraphics

//Extension for distance function and hashability
extension CGPoint: Hashable {
    static func |(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
        return sqrt(pow(rhs.x - lhs.x, 2.0) + pow(rhs.y - lhs.y, 2.0))
    }
    
    static func +(_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    static func -(_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    static func *(_ lhs: CGFloat, _ rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs * rhs.x, y: lhs * rhs.y)
    }
    
    static func /(_ rhs: CGPoint, _ lhs: CGFloat) -> CGPoint {
        return CGPoint(x: rhs.x / lhs, y: rhs.y / lhs)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}
