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
    
    init(_ point: CGPoint) {
        self.init(x: point.x, y: point.y, z: 0)
    }
    
    //Convert to a two dimensional point
    func flatten() -> CGPoint {
        return CGPoint(x: x, y: y)
    }
    
    func distance(_ other: Vertex) -> CGFloat {
        return sqrt(pow(other.x - x, 2) + pow(other.y - y, 2) + pow(other.z - z, 2))
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
    
    //Converts to C++ wrapper type for use in Metal compression shader
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
        return MetalEdge(segments: (MetalSegment(origin: origin.harden(), outpost: outpost.harden(), markline: MarkLine()), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment()), count: Int32(1), polygon: UInt32(id))
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
    
    //Finds the intersection between two lines
    static func &(first: Line, second: Line) -> CGPoint? {
        //Calculate line vector components
        let delta1x = first.outpost.x - first.origin.x
        let delta1y = first.outpost.y - first.origin.y
        let delta2x = second.outpost.x - second.origin.x
        let delta2y = second.outpost.y - second.origin.y

        //Create a 2D matrix from the vectors and calculate the determinant
        let determinant = delta1x * delta2y - delta2x * delta1y
        
        //If determinant is zero (or very close as approximation), the lines are parallel or colinear
        if abs(determinant) < 0.0001 {
            return nil
        }

        //If the coefficients are between 0 and 1 (meaning they occur between their beginnings and ends not off in the distance), there is an intersection
        let ab = ((first.origin.y - second.origin.y) * delta2x - (first.origin.x - second.origin.x) * delta2y) / determinant
        if ab > 0 && ab < 1 {
            let cd = ((first.origin.y - second.origin.y) * delta1x - (first.origin.x - second.origin.x) * delta1y) / determinant
            if cd > 0 && cd < 1 {
                //Calculate exact intersection point
                let intersectX = first.origin.x + ab * delta1x
                let intersectY = first.origin.y + ab * delta1y
                return CGPoint(x: intersectX, y: intersectY)
            }
        }
        
        //Lines don't cross
        return nil
    }
}

//A goal is an edge
typealias Goal = Edge

//Represents a 3D Box
struct Region: Codable {
    var origin: Vertex
    var outpost: Vertex
    private var points: [Vertex] {
        var temp: [Vertex] = []
        for x in [origin.x, outpost.x] {
            for y in [origin.y, outpost.y] {
                for z in [origin.z, outpost.z] {
                    temp.append(Vertex(x: x, y: y, z: z))
                }
            }
        }
        return temp
    }
    
    private enum CodingKeys: String, CodingKey {
        case origin, outpost
    }
    
    //Calculates the outline of the falttened region
    func flatten(transform: Transform) -> Polygon {
        
        let vertices = transform.method(Polygon(vertices: points)).vertices
        
        func sweep(center: Vertex, point: Vertex) -> CGFloat {
            let dot: CGFloat = (point.y - center.y)
            let dist = sqrt(pow(center.x - point.x, 2) + pow(center.y - point.y, 2))
            if dist == 0 {
                return 0
            }
            let theta = acos(dot / dist)
            if point.x < center.x {
                return 3.14159 * 2 - theta
            }
            return theta
        }
        
        var center = Vertex(x: 0, y: 0, z: 0)
        for vert in vertices {
            center.x += vert.x
            center.y += vert.y
            center.z += vert.z
        }
        center.x /= CGFloat(vertices.count)
        center.y /= CGFloat(vertices.count)
        center.z /= CGFloat(vertices.count)
        
        //Lol, get fucked future me
        var raw = vertices.map { (angle: sweep(center: center, point: $0), vert: $0) }.sorted { $0.angle > $1.angle }
        print(raw)
        var sorted = raw.map { $0.vert }
        var removes: [Int] = []
        
        func hits(_ first: Line, _ second: Line) -> Bool {
            //Calculate line vector components
            let delta1x = first.outpost.x - first.origin.x
            let delta1y = first.outpost.y - first.origin.y
            let delta2x = second.outpost.x - second.origin.x
            let delta2y = second.outpost.y - second.origin.y

            //Create a 2D matrix from the vectors and calculate the determinant
            let determinant = delta1x * delta2y - delta2x * delta1y
            
            //If determinant is zero (or very close as approximation), the lines are parallel or colinear
            if abs(determinant) < 0.0001 {
                return false
            }

            //If the coefficients are between 0 and 1 (meaning they occur between their beginnings and ends not off in the distance), there is an intersection
            let cd = ((first.origin.y - second.origin.y) * delta1x - (first.origin.x - second.origin.x) * delta1y) / determinant
            let ab = ((first.origin.y - second.origin.y) * delta2x - (first.origin.x - second.origin.x) * delta2y) / determinant
            if cd > 0 && cd < 1 && ab > 1 {
                return true
            }
            return false
        }
        
        for i in 0 ..< sorted.count {
            let before = sorted[i - 1 < 0 ? sorted.count - 1 : i - 1]
            let after = sorted[(i + 1) % sorted.count]
            let current = sorted[i]
            if current == before {
                removes.append(i)
                continue
            }
            if hits(Line(origin: center.flatten(), outpost: current.flatten()), Line(origin: before.flatten(), outpost: after.flatten())) {
                print(i.description + " hit")
                removes.append(i)
            }
        }
        
        print(removes)
        
        for i in removes.sorted().reversed() {
            sorted.remove(at: i)
        }
        
        return Polygon(vertices: sorted)
    }
    
    func restrain(position: CGPoint, transform: Transform, frame: CGRect, rotation: CGAffineTransform = CGAffineTransform()) -> CGPoint {
        let flattened: [CGPoint] = flatten(transform: transform).vertices.map { $0.flatten().applying(rotation) }
        
        let ymax = flattened.max(by: { $0.y < $1.y })!.y -  frame.height / 2
        let ymin = flattened.max(by: { $0.y > $1.y })!.y +  frame.height / 2
        let xmax = flattened.max(by: { $0.x < $1.x })!.x - frame.width / 2
        let xmin = flattened.max(by: { $0.x > $1.x })!.x + frame.width / 2
        
        var y = min(max(ymin, position.y), ymax)
        var x = min(max(xmin, position.x), xmax)
        
        if ymin > ymax {
            y = frame.height / 2
        }
        if xmin > xmax {
            x = frame.width / 2
        }
        
        return CGPoint(x: x, y: y)
    }
    
    init(origin: Vertex, outpost: Vertex) {
        self.origin = origin
        self.outpost = outpost
//        for x in [origin.x, outpost.x] {
//            for y in [origin.y, outpost.y] {
//                for z in [origin.z, outpost.z] {
//                    points.append(Vertex(x: x, y: y, z: z))
//                }
//            }
//        }
    }
}

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
