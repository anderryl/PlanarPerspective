//
//  Plane.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 5/18/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit

enum Plane {
    case TOP
    case BOTTOM
    case FRONT
    case BACK
    case LEFT
    case RIGHT
}

/*
 Front represents the xy plane
                    ___------___
              ___---            ---___
              ---___            ___---
              |     ---______---     |
              |          |           |
              |          |           |
              |          |           |
              |          |           |
              |          |           |
              ---___     |      ___---
                    ---__|___---
 */

typealias TransformFactory = (_ phase: CGFloat) -> (_ vertice: Polygon) -> Polygon

typealias Transform = (_ polygon: Polygon) -> Polygon
                                               
struct Vertex: Codable, Hashable {
    var x: CGFloat
    var y: CGFloat
    var z: CGFloat
    
    func flatten() -> CGPoint{
        return CGPoint(x: x, y: y)
    }
}

typealias Position = Vertex

struct Polygon: Codable, Hashable {
    var vertices: [Vertex]
    
    func lines() -> [Line] {
        var lines: [Line] = []
        for i in 0 ..< vertices.count - 1 {
            lines.append(Line(origin: vertices[i].flatten(), outpost: vertices[i + 1].flatten()))
        }
        lines.append(Line(origin: vertices[0].flatten(), outpost: vertices.last!.flatten()))
        return lines
    }
    
    
    func edges() -> [Edge] {
        var edges: [Edge] = []
        for i in 0 ..< vertices.count - 1 {
            edges.append(Edge(origin: vertices[i], outpost: vertices[i + 1]))
        }
        //Note: In order to increase compression efficiency, last vertice must come before first for the callback
        edges.append(Edge(origin: vertices.last!, outpost: vertices[0]))
        return edges
    }
}

struct Edge: Codable {
    var origin: Vertex
    var outpost: Vertex
    
    func flatten() -> Line {
        return Line(origin: origin.flatten(), outpost: outpost.flatten())
    }
}

//NOTE: Rename to line segment at some point
struct Line {
    var origin: CGPoint
    var outpost: CGPoint
}

typealias Goal = Edge

//Cause it looks like a line segment and line segments have length
extension CGPoint {
    static func |(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
        return sqrt(pow(rhs.x - lhs.x, 2.0) + pow(rhs.y - lhs.y, 2.0))
    }
}
