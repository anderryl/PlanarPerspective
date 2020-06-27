//
//  PlayerBuilder.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 6/17/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit

class PlayerBuilder: Builder {
    var level: LevelView
    private var loc: CGPoint = CGPoint(x: 0, y: 0)
    
    required init(level: LevelView) {
        self.level = level
    }
    
    func build(from transform: Transform) -> [DrawItem] {
        let pos: CGPoint = transform(Polygon(vertices: [level.position])).vertices[0].flatten()
        loc = pos
        return [DrawItem.CIRCLE(pos, 10.0, .init(srgbRed: 0, green: 0, blue: 0, alpha: 1))]
    }
    
    func location() -> CGPoint {
        return loc
    }
}
