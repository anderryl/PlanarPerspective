//
//  Scaler.swift
//  PlanarPerspective
//
//  Created by Rylie Anderson on 12/1/22.
//  Copyright © 2022 Anderson, Todd W. All rights reserved.
//

import Foundation
import CoreGraphics

typealias Scaler = (_ bounds: Polygon, _ frame: CGRect, _ state: Int) -> CGFloat

enum ScalerFactory {
    case BOUNDED
    case TRANSITING(MatrixTransform, MatrixTransform, Region, Int, Int)
    
    func build() -> Scaler {
        func bind(_ bounds: Polygon, _ frame: CGRect, _ state: Int) -> CGFloat {
            let vertices = bounds.curves.map { $0.origin.flatten() }
            let xmap = vertices.map { $0.x }
            let ymap = vertices.map { $0.y }

            let xspan = xmap.max()! - xmap.min()!
            let yspan = ymap.max()! - ymap.min()!

            return max(frame.width / xspan, frame.height / yspan)
        }
        switch self {
        case .BOUNDED:
            return bind(_:_:_:)
        case .TRANSITING(let initial, let final, let region, let beginning, let length):
            return { (_ bounds: Polygon, _ frame: CGRect, _ state: Int) in
                let lower = bind(region.flatten(transform: initial), frame, state)
                let upper = bind(region.flatten(transform: final), frame, state)
                return (CGFloat(state - beginning) / CGFloat(length)) * (upper - lower) + lower
            }
        }
    }
}
