//
//  State.swift
//  PlanarPerspective
//
//  Created by Rylie Anderson on 9/7/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import CoreGraphics

enum State {
    case REST
    case MOTION([CGPoint])
    case TRANSITION(Plane, Plane)
}
