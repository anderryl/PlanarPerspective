//
//  State.swift
//  PlanarPerspective
//
//  Created by Rylie Anderson on 9/7/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import CoreGraphics

//Represents the current state of the game
enum State {
    case REST
    case MOTION([Position])
    case TRANSITION(TransitionState)
    case ARRIVED
    
    static func ~~(_ lhs: State, _ rhs: State) -> Bool {
        switch lhs {
        case .REST:
            switch rhs {
            case .REST:
                return true
            default:
                return false
            }
        case .TRANSITION(_):
            switch rhs {
            case .TRANSITION(_):
                return true
            default:
                return false
            }
        case .MOTION(_):
            switch rhs {
            case .MOTION(_):
                return true
            default:
                return false
            }
        case .ARRIVED:
            switch rhs {
            case .ARRIVED:
                return true
            default:
                return false
            }
        }
    }
}
