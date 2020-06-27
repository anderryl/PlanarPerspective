//
//  LogicHandler.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 6/11/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit

class LogicHandler {
    unowned var level: LevelView
    
    init(level: LevelView) {
        self.level = level
    }
    
    func attemptTransition(from first: Plane, to second: Plane) {
        switch level.state {
        case .REST:
            level.graphics.transition(from: first, to: second)
            level.state = .TRANSITION(first, second)
            level.plane = second
        default:
            //Negative Feedback
            return
        }
    }
    
    func attemptMove(to point: CGPoint) {
        switch level.state {
        case .REST:
            let pos = ProjectionHandler.compress(vertex: level.position, onto: level.plane)
            if level.contact.findContact(from: pos.flatten(), to: point) != nil {
                //Negative feedback
                return
            }
            level.state = .MOTION([point])
            level.motion.input()
        case .MOTION(var queue):
            if level.contact.findContact(from: queue.last!, to: point) != nil {
                //Negative feedback
                return
            }
            queue.append(point)
            level.state = .MOTION(queue)
        default:
            //Negative Feedback
            return
        }
    }
}
