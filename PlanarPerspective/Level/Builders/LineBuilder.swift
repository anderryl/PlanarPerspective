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
    //Compress the polygons and return them as drawable lines
    func  build(from snapshot: BuildSnapshot) -> [DrawItem] {
        var ret: [DrawItem] = []
        for line in snapshot.lines {
            ret.append(.ARC(line.origin, line.outpost, line.control, .init(srgbRed: 0.0, green: 0.0, blue: 0.0, alpha: line.intensity), line.thickness, 0))
        }
        return ret
    }
}
