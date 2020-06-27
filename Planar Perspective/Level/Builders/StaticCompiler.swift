//
//  StaticCompiler.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 6/5/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit

class StaticCompiler: Compiler {
    unowned var level: LevelView
    internal var plane: Plane
    internal var transform: Transform
    internal var lines: LineBuilder
    internal var motion: MotionBuilder
    internal var player: PlayerBuilder
    internal var goal: GoalBuilder
    
    init(level: LevelView, plane: Plane) {
        self.level = level
        self.plane = plane
        self.transform = ProjectionHandler.component(of: plane)
        lines = LineBuilder(level: level)
        player = PlayerBuilder(level: level)
        motion = MotionBuilder(level: level)
        goal = GoalBuilder(level: level)
    }
    
    func compile() -> [DrawItem] {
        var items: [DrawItem] = []
        items.append(contentsOf: lines.build(from: transform))
        items.append(contentsOf: motion.build(from: transform))
        items.append(contentsOf: player.build(from: transform))
        items.append(contentsOf: goal.build(from: transform))
        var translated: [DrawItem] = []
        let location = player.location()
        let dx = level.frame.width / 2 - location.x
        let dy = level.frame.height / 2 - location.y
        let translation = CGAffineTransform(translationX: dx, y: dy)
        for item in items {
            switch item {
            case .CIRCLE(let position, let radius, let color, let layer):
                translated.append(.CIRCLE(position.applying(translation), radius, color, layer))
            case .RECTANGLE(let position, let size, let color, let layer):
                translated.append(.RECTANGLE(position.applying(translation), size, color, layer))
            case .LINE(let origin, let outpost, let color, let layer):
                translated.append(.LINE(origin.applying(translation), outpost.applying(translation), color, layer))
            default:
                break
            }
        }
        return translated
    }
}
