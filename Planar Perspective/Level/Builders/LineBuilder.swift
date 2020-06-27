//
//  LineBuilder.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 5/18/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation

class LineBuilder: Builder {
    unowned var level: LevelView
    
    required init(level: LevelView) {
        self.level = level
    }
    
    func  build(from transform: Transform) -> [DrawItem] {
        var ret: [DrawItem] = []
        for line in level.compression!.compress(with: transform, reverse: false) {
            ret.append(.LINE(line.origin, line.outpost, .init(srgbRed: 0.0, green: 0.0, blue: 0.0, alpha: 1.0), 0))
        }
        return ret
    }
}
