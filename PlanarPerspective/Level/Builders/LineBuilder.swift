//
//  LineBuilder.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 5/18/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation

//Builder for environment lines
class LineBuilder: Builder {
    //Supervisor
    unowned var level: LevelView
    
    //Initializes from supervisor reference
    required init(level: LevelView) {
        self.level = level
    }
    
    //Compress the polygons and return them as drawable lines
    func  build(from transform: Transform, state: Int) -> [DrawItem] {
        var ret: [DrawItem] = []
        for line in level.compression!.compress(with: transform) {
            ret.append(.LINE(line.origin, line.outpost, .init(srgbRed: 0.0, green: 0.0, blue: 0.0, alpha: 1.0), 0))
        }
        return ret
    }
}
