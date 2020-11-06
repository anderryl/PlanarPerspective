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
    internal var plane: Plane
    internal var transform: Transform
    internal var lines: LineBuilder
    internal var motion: MotionBuilder
    internal var player: PlayerBuilder
    internal var rstate: Int
    internal var frame: Int = 0
    
    init(level: LevelView, plane: Plane, state: Int) {
        self.level = level
        self.plane = plane
        self.transform = ProjectionHandler.component(of: plane)
        self.rstate = state
        lines = LineBuilder(level: level)
        player = PlayerBuilder(level: level)
        motion = MotionBuilder(level: level)
    }
    
    func registerInvalid(at point: CGPoint) {
        motion.registerInvalid(at: point)
    }
    
    func compile(state: Int) -> [DrawItem] {
        var items: [DrawItem] = []
        items.append(contentsOf: lines.build(from: transform, state: rstate))
        items.append(contentsOf: motion.build(from: transform, state: rstate))
        items.append(contentsOf: player.build(from: transform, state: rstate))
        
        let flatB = ProjectionHandler.compress(vertex: level.goal.origin, onto: level.plane).flatten()
        let flatE = ProjectionHandler.compress(vertex: level.goal.outpost, onto: level.plane).flatten()
        
        frame += 1
        
        var translated: [DrawItem] = []
        let location = player.location()
        let dx = level.frame.width / 2 - location.x
        let dy = level.frame.height / 2 - location.y
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
