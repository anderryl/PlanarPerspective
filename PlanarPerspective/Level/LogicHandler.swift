//
//  LogicHandler.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 6/11/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit

//Delegate class for handling the high-level game logic
class LogicHandler {
    //Supervisor
    unowned var level: LevelView
    
    //Initializes delegate with supervisor reference
    init(level: LevelView) {
        self.level = level
    }
    
    //Checks if player is inside the goal area two-dimensionally
    func check() {
        //Flatten the goal endpoints and the player position
        let flatB = ProjectionHandler.compress(vertex: level.goal.origin, onto: level.plane).flatten()
        let flatE = ProjectionHandler.compress(vertex: level.goal.outpost, onto: level.plane).flatten()
        let flatP = ProjectionHandler.compress(vertex: level.position, onto: level.plane).flatten()
        
        //If the player position is within the goal area, begin win sequence
        if min(flatE.x, flatB.x) < flatP.x && flatP.x < max(flatE.x, flatB.x) {
            if min(flatE.y, flatB.y) < flatP.y && flatP.y < max(flatE.y, flatB.y) {
                level.arrived()
            }
        }
        return
    }
    
    //Attempts a transition if feasible
    func attemptTransition(from first: Plane, to second: Plane) {
        //If at rest, perform the transition
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
    
    //Attempts a movement if feasible
    func attemptMove(to point: CGPoint) {
        //If at rest or in motion, perform the movement
        switch level.state {
        case .REST:
            let pos = ProjectionHandler.compress(vertex: level.position, onto: level.plane)
            //If there is a collision notify the graphics handler
            if let contact = level.contact.findContact(from: pos.flatten(), to: point) {
                level.graphics.registerInvalid(at: contact)
                return
            }
            level.state = .MOTION([point])
            level.motion.input()
        case .MOTION(var queue):
            //If there is a collision notify the graphics handler
            if let contact = level.contact.findContact(from: queue.last!, to: point) {
                level.graphics.registerInvalid(at: contact)
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
