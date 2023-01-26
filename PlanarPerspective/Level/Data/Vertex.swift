//
//  Vertex.swift
//  PlanarPerspective
//
//  Created by Rylie Anderson on 11/25/22.
//  Copyright © 2022 Anderson, Todd W. All rights reserved.
//

import Foundation
import CoreGraphics

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
    
    func applying(_ transform: CGAffineTransform) -> Vertex {
        let pt = flatten().applying(transform)
        return Vertex(x: pt.x, y: pt.y, z: z)
    }
    
    //Convert to MetalVertex Objective-C wrapper type for use with the Metal compression shader
    func harden() -> MetalVertex {
        return MetalVertex(x: Float(x), y: Float(y), z: Float(z))
    }
    
    static func +(_ lhs: Vertex, _ rhs: Vertex) -> Vertex {
        return Vertex(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }
    
    static func -(_ lhs: Vertex, _ rhs: Vertex) -> Vertex {
        return Vertex(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }
    
    static func *(_ lhs: CGFloat, _ rhs: Vertex) -> Vertex {
        return Vertex(x: lhs * rhs.x, y: lhs * rhs.y, z: lhs * rhs.z)
    }
    
    static func random(in range: ClosedRange<CGFloat>) -> Vertex {
        return Vertex(x: CGFloat.random(in: range), y: CGFloat.random(in: range), z: CGFloat.random(in: range))
    }
}

//Position is vertex
typealias Position = Vertex
