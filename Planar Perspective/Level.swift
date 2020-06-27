//
//  Level.swift
//  Planar Perspective
//
//  Created by Home on 6/27/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation

class Level: Codable {
    var polygons: [Polygon]
    var goal: Goal
    var position: Position
    
    init(polygons: [Polygon], goal: Goal, position: Position) {
        self.polygons = polygons
        self.goal = goal
        self.position = position
    }
}
