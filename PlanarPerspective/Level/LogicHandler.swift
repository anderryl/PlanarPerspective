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
        let flatB = (level.matrix * level.goal.origin).flatten()
        let flatE = (level.matrix * level.goal.outpost).flatten()
        let flatP = (level.matrix * level.position).flatten()
        
        //If the player position is within the goal area, begin win sequence
        if min(flatE.x, flatB.x) < flatP.x && flatP.x < max(flatE.x, flatB.x) {
            if min(flatE.y, flatB.y) < flatP.y && flatP.y < max(flatE.y, flatB.y) {
                level.arrived()
            }
        }
        return
    }
    
    func propogate() {
        switch level.state {
        case .TRANSITION(let factory, let progress, let length):
            level.matrix = factory(CGFloat(progress) / CGFloat(length))
            if progress == length {
                updateState(.REST)
                level.matrix = level.matrix.normalized()
            }
            else {
                updateState(.TRANSITION(factory, progress + 1, length))
            }
        default:
            break
        }
    }
    
    //Attempts a transition if feasible
    func attemptTransition(direction: Direction) {
        //If at rest, perform the transition
        switch level.state {
        case .REST:
            updateState(.TRANSITION(level.matrix.slide(in: direction), 0, 30))
        default:
            //Negative Feedback
            return
        }
    }
    
    //Attempts a transition if feasible
    func attemptTwist(rotation: Rotation) {
        //If at rest, perform the transition
        switch level.state {
        case .REST:
            updateState(.TRANSITION(level.matrix.twist(in: rotation), 0, 30))
        default:
            //Negative Feedback
            return
        }
    }
    
    //Attempts a movement if feasible
    func attemptMove(to point: Position) {
        //If at rest or in motion, perform the movement
        switch level.state {
        case .REST:
            //If there is a collision notify the graphics handler
            if let contact = level.contact.findContact(from: level.position, to: point) {
                level.graphics.registerInvalid(at: contact)
                return
            }
            updateState(.MOTION([point]))
            level.motion.input()
        case .MOTION(var queue):
            //If there is a collision notify the graphics handler
            if let contact = level.contact.findContact(from: queue.last!, to: point) {
                level.graphics.registerInvalid(at: contact)
                return
            }
            queue.append(point)
            updateState(.MOTION(queue))
        default:
            //Negative Feedback
            return
        }
    }
    
    func updateState(_ nstate: State) {
        if !(nstate ~~ level.state) {
            level.graphics.notifyStateChange(nstate)
        }
        level.state = nstate
    }
}
