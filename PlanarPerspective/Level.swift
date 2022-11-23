//
//  Level.swift
//  Planar Perspective
//
//  Created by Home on 6/27/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation

//Data type for storing and accessing level data
class Level: Codable {
    var polygons: [Polygon]
    var goal: Region
    var position: Position
    var bounds: Region
    
    init(polygons: [Polygon], goal: Region, position: Position, bounds: Region) {
        self.polygons = polygons
        self.goal = goal
        self.position = position
        self.bounds = bounds
    }
}
