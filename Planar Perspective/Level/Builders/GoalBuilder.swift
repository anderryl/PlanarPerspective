//
//  GoalBuilder.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 6/23/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit

class GoalBuilder: Builder {
    var level: LevelView
    
    required init(level: LevelView) {
        self.level = level
    }
    
    func build(from transform: Transform) -> [DrawItem] {
        let flat = transform(Polygon(vertices: [level.goal.origin, level.goal.outpost]))
        let lines = flat.lines()
        let one = lines.first!.origin
        let two = lines.first!.outpost
        return [.RECTANGLE(one, CGSize(width: two.x - one.x, height: two.y - one.y), .init(srgbRed: 0, green: 1, blue: 0, alpha: 1))]
    }
}
