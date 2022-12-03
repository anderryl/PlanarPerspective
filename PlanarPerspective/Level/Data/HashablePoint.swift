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
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}
