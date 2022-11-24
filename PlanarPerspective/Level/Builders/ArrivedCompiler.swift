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
    internal var lines: LineBuilder
    internal var motion: MotionBuilder
    internal var player: PlayerBuilder
    internal var frame: Int = 0
    
    required init() {
        lines = LineBuilder()
        player = PlayerBuilder()
        motion = MotionBuilder()
    }    
    func compile(_ snapshot: BuildSnapshot) -> [DrawItem] {
        var items: [DrawItem] = []
        items.append(contentsOf: lines.build(from: snapshot))
        items.append(contentsOf: motion.build(from: snapshot))
        items.append(contentsOf: player.build(from: snapshot))
        
        frame += 1
        
        var translated: [DrawItem] = []
        let restrained = snapshot.position
        let dx = snapshot.frame.width / 2 - restrained.x
        let dy = snapshot.frame.height / 2 - restrained.y
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
