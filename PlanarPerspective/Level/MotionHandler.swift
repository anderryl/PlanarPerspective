//
//  MotionHandler.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 6/14/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit

//Delegate class for handling player motion
class MotionHandler {
    //Supervisor view
    private unowned let level: LevelView
    private var rate: CGFloat = 8
    
    //The current destination
    private var current: Position?
    //The movement vectors
    private var dx: CGFloat?
    private var dy: CGFloat?
    //Current movement duration (in frames)
    private var duration: Int?
    //The current frame of motion
    private var frame: Int?
    
    //Initializes delegate from supervisor reference
    init(level: LevelView) {
        self.level = level
    }
    
    //Notifies delegate of input
    func input() {
        //If the current state is motion, there is a queued item, and there is no current destination, begin motion
        switch level.state {
        case .MOTION(let queue):
            if let next = queue.first, current == nil {
                setCurrent(next)
            }
        default:
            return
        }
    }
    
    //Called upon arriving at current destination point
    func arrived() {
        //If in motion state, update game position, update queue, and move on to next item (if applicable)
        //Otherwise reset to inactivity and set state to rest
        switch level.state {
        case .MOTION(var queue):
            level.position = queue.first!
            queue.remove(at: 0)
            if queue.count == 0 {
                current = nil
                dx = nil
                dy = nil
                duration = nil
                frame = nil
                level.state = .REST
            }
            else {
                level.state = .MOTION(queue)
                setCurrent(queue[0])
            }
        default:
            current = nil
            dx = nil
            dy = nil
            duration = nil
            frame = nil
            level.state = .REST
        }
    }
    
    //Sets the new destination point
    func setCurrent(_ point: Position) {
        current = point
        let pos = (level.matrix * level.position).flatten()
        let tp = (level.matrix * point).flatten()
        let x = tp.x - pos.x
        let y = tp.y - pos.y
        let time = Int((pos | tp) / rate)
        duration = time
        frame = 0
        dx = x / CGFloat(time)
        dy = y / CGFloat(time)
    }
    
    //Called each frame to move the player
    func move() {
        if dx != nil && dy != nil {
            //Update game position
//            var pos = (level.matrix * level.position).flatten()
//            pos.x += dx!
//            pos.y += dy!
//            level.position = ProjectionHandler.unfold(point: pos, onto: level.position, against: level.matrix)
            let offset = level.matrix.inverted() * Position(x: dx!, y: dy!, z: 0)
            level.position = level.position + offset
            
            frame! += 1
            //Check win condition
            level.logic.check()
            //Check status
            if frame! >= duration! {
                arrived()
            }
        }
    }
}
