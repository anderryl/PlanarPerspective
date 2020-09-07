//
//  MotionHandler.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 6/14/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit

class MotionHandler {
    private unowned let level: LevelView
    private var rate: CGFloat = 2
    private var current: CGPoint?
    private var dx: CGFloat?
    private var dy: CGFloat?
    private var duration: Int?
    private var frame: Int?
    
    init(level: LevelView) {
        self.level = level
    }
    
    func input() {
        switch level.state {
        case .MOTION(let queue):
            if let next = queue.first, current == nil {
                setCurrent(next)
            }
        default:
            return
        }
    }
    
    func arrived() {
        switch level.state {
        case .MOTION(var queue):
            level.position = ProjectionHandler.unfold(point: queue.first!, onto: level.position, from: level.plane)
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
    
    func setCurrent(_ point: CGPoint) {
        current = point
        let pos = ProjectionHandler.compress(vertex: level.position, onto: level.plane).flatten()
        let x = point.x - pos.x
        let y = point.y - pos.y
        let time = Int((pos | point) / rate)
        duration = time
        frame = 0
        dx = x / CGFloat(time)
        dy = y / CGFloat(time)
        
    }
    
    func move() {
        if dx != nil && dy != nil {
            var pos = ProjectionHandler.compress(vertex: level.position, onto: level.plane).flatten()
            pos.x += dx!
            pos.y += dy!
            level.position = ProjectionHandler.unfold(point: pos, onto: level.position, from: level.plane)
            frame! += 1
            if frame! >= duration! {
                arrived()
            }
        }
    }
}
