//
//  ArrivedCompiler.swift
//  PlanarPerspective
//
//  Created by Rylie Anderson on 10/31/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit

//NOT YET IN USE
class ArrivedCompiler: Compiler {
    unowned var level: LevelView
    internal var lines: LineBuilder
    internal var motion: MotionBuilder
    internal var player: PlayerBuilder
    internal var rstate: Int
    internal var frame: Int = 0
    internal var center: CGPoint?
    
    init(supervisor: LevelView, state: Int) {
        self.level = supervisor
        self.rstate = state
        lines = LineBuilder(level: level)
        player = PlayerBuilder(level: level)
        motion = MotionBuilder(level: level)
    }
    
    func getCenter() -> CGPoint {
        if center == nil {
            return level.region.restrain(position: player.location(), transform: level.matrix, frame: level.frame)
        }
        return center!
    }
    
    func compile(_ snapshot: BuildSnapshot) -> [DrawItem] {
        var items: [DrawItem] = []
        items.append(contentsOf: lines.build(from: level.matrix, state: rstate))
        items.append(contentsOf: motion.build(from: level.matrix, state: rstate))
        items.append(contentsOf: player.build(from: level.matrix, state: rstate))
        
        frame += 1
        
        var translated: [DrawItem] = []
        let restrained = level.region.restrain(position: (level.matrix * level.position).flatten(), transform: level.matrix, frame: level.frame)
        center = restrained
        let dx = level.frame.width / 2 - restrained.x
        let dy = level.frame.height / 2 - restrained.y
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
        return translated
    }
}
