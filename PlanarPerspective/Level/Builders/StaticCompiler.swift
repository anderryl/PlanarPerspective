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
    
    //Children builders for each level element
    internal var lines: LineBuilder
    internal var motion: MotionBuilder
    internal var player: PlayerBuilder
    internal var goal: GoalBuilder
    
    //Initializes from supervisor reference
    required init() {
        lines = LineBuilder()
        player = PlayerBuilder()
        motion = MotionBuilder()
        goal = GoalBuilder()
    }
    
    //Compile the results of each child builder
    func compile(_ snapshot: BuildSnapshot) -> [DrawItem] {
        //Compile results
        var items: [DrawItem] = []
        items.append(contentsOf: lines.build(from: snapshot))
        items.append(contentsOf: motion.build(from: snapshot))
        items.append(contentsOf: player.build(from: snapshot))
        items.append(contentsOf: goal.build(from: snapshot))
        var translated: [DrawItem] = []
        
        //Find offset
        let dx = snapshot.frame.width / 2 - snapshot.center.x
        let dy = snapshot.frame.height / 2 - snapshot.center.y
        
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
