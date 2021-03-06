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
    //The plane of this compiler
    internal var plane: Plane
    //The transform for this plane
    internal var transform: Transform
    //Children builders for each level element
    internal var lines: LineBuilder
    internal var motion: MotionBuilder
    internal var player: PlayerBuilder
    internal var goal: GoalBuilder
    
    //Initializes from supervisor reference
    init(level: LevelView, plane: Plane) {
        self.level = level
        self.plane = plane
        self.transform = ProjectionHandler.component(of: plane)
        lines = LineBuilder(level: level)
        player = PlayerBuilder(level: level)
        motion = MotionBuilder(level: level)
        goal = GoalBuilder(level: level)
    }
    
    //Registers an invalid movement attempt for visualization
    func registerInvalid(at point: CGPoint) {
        motion.registerInvalid(at: point)
    }
    
    //Compile the results of each child builder
    func compile(state: Int) -> [DrawItem] {
        //Compile results
        var items: [DrawItem] = []
        items.append(contentsOf: lines.build(from: transform, state: state))
        items.append(contentsOf: motion.build(from: transform, state: state))
        items.append(contentsOf: player.build(from: transform, state: state))
        items.append(contentsOf: goal.build(from: transform, state: state))
        var translated: [DrawItem] = []
        
        //Find offset
        let location = player.location()
        let dx = level.frame.width / 2 - location.x
        let dy = level.frame.height / 2 - location.y
        
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
