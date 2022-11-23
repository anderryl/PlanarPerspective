//
//  StaticCompiler.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 6/5/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit

//Graphics Compiler for the REST and MOTION states
class StaticCompiler: Compiler {
    
    //Supervisor
    unowned var level: LevelView
    
    //Children builders for each level element
    internal var lines: LineBuilder
    internal var motion: MotionBuilder
    internal var player: PlayerBuilder
    internal var goal: GoalBuilder
    internal var center: CGPoint?
    
    //Initializes from supervisor reference
    init(level: LevelView) {
        self.level = level
        lines = LineBuilder(level: level)
        player = PlayerBuilder(level: level)
        motion = MotionBuilder(level: level)
        goal = GoalBuilder(level: level)
    }
    
    //Registers an invalid movement attempt for visualization
    func registerInvalid(at point: CGPoint) {
        switch level.state {
        case .MOTION(let queue):
            motion.registerInvalid(from: (level.matrix * queue.last!).flatten(), to: point)
        case .REST:
            motion.registerInvalid(from: (level.matrix * level.position).flatten(), to: point)
        default:
            break
        }
    }
    
    func getCenter() -> CGPoint {
        if center == nil {
            return level.region.restrain(position: player.location(), transform: level.matrix, frame: level.frame)
        }
        return center!
    }
    
    //Compile the results of each child builder
    func compile(_ snapshot: BuildSnapshot) -> [DrawItem] {
        //Compile results
        var items: [DrawItem] = []
        items.append(contentsOf: lines.build(from: level.matrix, state: snapshot.state))
        items.append(contentsOf: motion.build(from: level.matrix, state: snapshot.state))
        items.append(contentsOf: player.build(from: level.matrix, state: snapshot.state))
        items.append(contentsOf: goal.build(from: level.matrix, state: snapshot.state))
        var translated: [DrawItem] = []
        
        //Find offset
        let restrained = level.region.restrain(position: (level.matrix * level.position).flatten(), transform: level.matrix, frame: level.frame)
        center = restrained
        let dx = level.frame.width / 2 - restrained.x
        let dy = level.frame.height / 2 - restrained.y
        
        //Apply offset to compiled results
        var translation = CGAffineTransform(translationX: dx, y: dy)
        for item in items {
            switch item {
            case .CIRCLE(let position, let radius, let color, let layer):
                translated.append(.CIRCLE(position.applying(translation), radius, color, layer))
            case .RECTANGLE(let position, let size, let color, let layer):
                translated.append(.RECTANGLE(position.applying(translation), size, color, layer))
            case .LINE(let origin, let outpost, let color, let layer):
                translated.append(.LINE(origin.applying(translation), outpost.applying(translation), color, layer))
            case .PATH(let path, let color, let layer):
                translated.append(.PATH(path.copy(using: &translation)!, color, layer))
            }
        }
        
        //Return offset results
        return translated
    }
}
