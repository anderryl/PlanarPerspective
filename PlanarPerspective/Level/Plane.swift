//
//  Plane.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 5/18/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit

//Represents one of the six possible perspectives
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
              ---___    Top     ___---
              |     ---______---     |
              |          |           |
              |          |           |
              |   Front  |    Right  |
              |          |           |
              |          |           |
              ---___     |      ___---
                    ---__|___---
 */

//Creates Factory based on phase
typealias TransformFactory = (_ phase: CGFloat) -> Transform

//Trasforms and flattens polygons according to plane and transition state
struct Transform: Hashable, Equatable {
    static func == (lhs: Transform, rhs: Transform) -> Bool {
        if (lhs.from == rhs.from && lhs.to == rhs.to && lhs.prog == rhs.prog) {
            return true
        }
        return false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(to)
        hasher.combine(from)
        hasher.combine(abs(0.5 - prog))
    }
    
    var method: (_ polygon: Polygon) -> Polygon
    var from: Plane
    var to: Plane
    var prog: CGFloat
}
      
//Represents a three dimensional point
struct Vertex: Codable, Hashable {
    var x: CGFloat
    var y: CGFloat
    var z: CGFloat
    
    init(x: CGFloat, y: CGFloat, z: CGFloat) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    init(_ metal: MetalVertex) {
        self.init(x: CGFloat(metal.x), y: CGFloat(metal.y), z: CGFloat(metal.z))
    }
    
    //Convert to a two dimensional point
    func flatten() -> CGPoint {
        return CGPoint(x: x, y: y)
    }
    
    //Convert to MetalVertex Objective-C wrapper type for use with the Metal compression shader
    func harden() -> MetalVertex {
        return MetalVertex(x: Float(x), y: Float(y), z: Float(z))
    }
}

//Position is vertex
typealias Position = Vertex

//Represents an in-game polygon
struct Polygon: Codable, Hashable {
    var vertices: [Vertex]
    
    init(vertices: [Vertex]) {
        self.vertices = vertices
    }
    
    //Retreives the two dimensional lines that make up the edge of the polygons
    func lines() -> [Line] {
        var lines: [Line] = []
        for i in 0 ..< vertices.count - 1 {
            lines.append(Line(origin: vertices[i].flatten(), outpost: vertices[i + 1].flatten()))
        }
        lines.append(Line(origin: vertices[0].flatten(), outpost: vertices.last!.flatten()))
        return lines
    }
    
    //Retreives the three dimensional edges that make up the polygon's borders
    func edges() -> [Edge] {
        var edges: [Edge] = []
        for i in 0 ..< vertices.count - 1 {
            edges.append(Edge(origin: vertices[i], outpost: vertices[i + 1]))
        }
        //Note: In order to increase compression efficiency, last vertice must come before first for the callback
        edges.append(Edge(origin: vertices.last!, outpost: vertices[0]))
        return edges
    }
    
    //Retreives the vertices as two dimensional points
    func points() -> [CGPoint] {
        return vertices.map { (vertex) -> CGPoint in
            return CGPoint(x: vertex.x, y: vertex.y)
        }
    }
    
    //Converts to Objective-C wrapper type for use in Metal compression shader
    //VERY VERY MESSY
    func harden() -> MetalPolygon {
        var verts = (MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex())
        for i in 0 ..< vertices.count {
            let a = vertices[i].harden()
            switch i {
            case 0:
                verts.0 = a
            case 1:
                verts.1 = a
            case 2:
                verts.2 = a
            case 3:
                verts.3 = a
            case 4:
                verts.4 = a
            case 5:
                verts.5 = a
            case 6:
                verts.6 = a
            case 7:
                verts.7 = a
            case 8:
                verts.8 = a
            case 9:
                verts.9 = a
            case 10:
                verts.10 = a
            case 11:
                verts.11 = a
            case 12:
                verts.12 = a
            case 13:
                verts.13 = a
            case 14:
                verts.14 = a
            case 15:
                verts.15 = a
            case 16:
                verts.16 = a
            case 17:
                verts.17 = a
            case 18:
                verts.18 = a
            case 19:
                verts.19 = a
            default:
                break;
            }
            
        }
        return MetalPolygon(vertices: verts, count: Int32(vertices.count))
    }
    
    //Retreives the edges as MetalEdge wrapper types
    func hardedges(id: Int) -> [MetalEdge] {
        return edges().map { $0.harden(id: id) }
    }
    
    //Initialize from a MetalPolygon wrapper type
    init(_ metal: MetalPolygon) {
        self.vertices = []
        for i in 0 ..< metal.count {
            switch i {
            case 0:
                vertices.append(Vertex(metal.vertices.0))
            case 1:
                vertices.append(Vertex(metal.vertices.1))
            case 2:
                vertices.append(Vertex(metal.vertices.2))
            case 3:
                vertices.append(Vertex(metal.vertices.3))
            case 4:
                vertices.append(Vertex(metal.vertices.4))
            case 5:
                vertices.append(Vertex(metal.vertices.5))
            case 6:
                vertices.append(Vertex(metal.vertices.6))
            case 7:
                vertices.append(Vertex(metal.vertices.7))
            case 8:
                vertices.append(Vertex(metal.vertices.8))
            case 9:
                vertices.append(Vertex(metal.vertices.9))
            case 10:
                vertices.append(Vertex(metal.vertices.10))
            case 11:
                vertices.append(Vertex(metal.vertices.11))
            case 12:
                vertices.append(Vertex(metal.vertices.12))
            case 13:
                vertices.append(Vertex(metal.vertices.13))
            case 14:
                vertices.append(Vertex(metal.vertices.14))
            case 15:
                vertices.append(Vertex(metal.vertices.15))
            case 16:
                vertices.append(Vertex(metal.vertices.16))
            case 17:
                vertices.append(Vertex(metal.vertices.17))
            case 18:
                vertices.append(Vertex(metal.vertices.18))
            case 19:
                vertices.append(Vertex(metal.vertices.19))
            default:
                break;
            }
            
        }
    }
}

//Represents a three dimensional edge connecting two vertices
struct Edge: Codable {
    var origin: Vertex
    var outpost: Vertex
    
    //Retreives the two dimensional line associated with this edge
    func flatten() -> Line {
        return Line(origin: origin.flatten(), outpost: outpost.flatten())
    }
    
    //Converts to a MetalEdge wrapper type
    func harden(id: Int) -> MetalEdge {
        return MetalEdge(segments: (MetalSegment(origin: origin.harden(), outpost: outpost.harden()), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment()), count: Int32(1), polygon: UInt32(id))
    }
}

//NOTE: Rename to line segment at some point
struct Line {
    var origin: CGPoint
    var outpost: CGPoint
    
    init(origin: CGPoint, outpost: CGPoint) {
        self.origin = origin
        self.outpost = outpost
    }
    
    init(_ metal: MetalSegment) {
        self.origin = Vertex(metal.origin).flatten()
        self.outpost = Vertex(metal.outpost).flatten()
    }
}

//A goal is an edge
typealias Goal = Edge

//Extension for distance function and hashability
extension CGPoint: Hashable {
    static func |(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
        return sqrt(pow(rhs.x - lhs.x, 2.0) + pow(rhs.y - lhs.y, 2.0))
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}
