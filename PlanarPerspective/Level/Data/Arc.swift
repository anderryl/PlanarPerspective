//
//  Line.swift
//  PlanarPerspective
//
//  Created by Rylie Anderson on 11/25/22.
//  Copyright © 2022 Anderson, Todd W. All rights reserved.
//

import Foundation
import CoreGraphics

infix operator ^^

protocol Tangential {
    var tangents: [Tangent] { get }
    
    var A: CGPoint { get }
    var B: CGPoint { get }
    var C: CGPoint { get }
    
    var bounds: CGRect { get }
    
    func at(_ t: CGFloat) -> CGPoint
    
    func calculateTangents() -> [Tangent]
    
    func calculateBounds() -> CGRect
}

extension Tangential {
    func calculateTangents() -> [Tangent] {
        var mutable: [Tangent] = []
        
        let tolerance = 2.0
        
        func partition(start: CGFloat, end: CGFloat) {
            let mid = (start + end) / 2
            let midpoint = at(mid)
            let open = at(start)
            let closed = at(end)
            let path = open - closed
            let vector = midpoint - open
            let offset = ~(vector - (((vector <> path) / ~path) * path))
            if (offset < tolerance) {
                mutable.append(Tangent(origin: open, outpost: closed, start: start, end: end))
            }
            else {
                partition(start: start, end: mid)
                partition(start: mid, end: end)
            }
        }
        
        partition(start: 0.0, end: 1.0)
        
        return mutable
    }
    
    func calculateBounds() -> CGRect {
        let minx: CGFloat = tangents.reduce(CGFloat.greatestFiniteMagnitude, { min($1.origin.x, $1.outpost.x) < $0 ? min($1.origin.x, $1.outpost.x) : $0 })
        let miny: CGFloat = tangents.reduce(CGFloat.greatestFiniteMagnitude) { min($1.origin.y, $1.outpost.y) < $0 ? min($1.origin.y, $1.outpost.y) : $0 }
        let maxx: CGFloat = tangents.reduce(-100000000) { max($1.origin.x, $1.outpost.x) > $0 ? max($1.origin.x, $1.outpost.x) : $0 }
        let maxy: CGFloat = tangents.reduce(-100000000) { max($1.origin.y, $1.outpost.y) > $0 ? max($1.origin.y, $1.outpost.y) : $0 }
        return CGRect(origin: CGPoint(x: minx, y: miny), size: CGSize(width: maxx - minx, height: maxy - miny))
    }
}

class Arc: Tangential {
    var origin: CGPoint!
    var outpost: CGPoint!
    var control: CGPoint!
    
    var intensity: CGFloat
    var thickness: CGFloat
    
    internal var A: CGPoint
    internal var B: CGPoint
    internal var C: CGPoint
    
    lazy var tangents: [Tangent] = {
        return calculateTangents()
    }()
    
    lazy var bounds: CGRect = {
        return calculateBounds()
    }()
    
    init(origin: CGPoint, outpost: CGPoint, control: CGPoint, intensity: CGFloat, thickness: CGFloat) {
        assert(!origin.x.isNaN)
        self.origin = origin
        self.outpost = outpost
        self.control = control
        self.intensity = intensity
        self.thickness = thickness
        self.A = outpost - 2 * control + origin
        self.B = 2 * (control - origin)
        self.C = origin
    }
    
    init(A: CGPoint, B: CGPoint, C: CGPoint) {
        self.intensity = 0.0
        self.thickness = 0.0
        self.A = A
        self.B = B
        self.C = C
        self.origin = at(0)
        self.outpost = at(1)
        self.control = at(0.5)
    }
    
    convenience init(origin: CGPoint, outpost: CGPoint, control: CGPoint, thickness: CGFloat) {
        self.init(
            origin: origin,
            outpost: outpost,
            control: control,
            intensity: 1.0,
            thickness: thickness
        )
    }
    
    convenience init(origin: CGPoint, outpost: CGPoint, control: CGPoint) {
        self.init(
            origin: origin,
            outpost: outpost,
            control: control,
            intensity: 1.0,
            thickness: 1.0
        )
    }
    
    convenience init(origin: CGPoint, outpost: CGPoint, thickness: CGFloat) {
        self.init(
            origin: origin,
            outpost: outpost,
            control: (origin + outpost) / 2,
            intensity: 1.0,
            thickness: thickness
        )
    }
    
    convenience init(_ segment: MetalSegment) {
        self.init(
            origin: Vertex(segment.origin).flatten(),
            outpost: Vertex(segment.outpost).flatten(),
            control: ((Vertex(segment.origin) + Vertex(segment.outpost)) / 2).flatten(),
            intensity: 1.0,
            thickness: 1.0
        )
    }
    
    func at(_ t: CGFloat) -> CGPoint {
        return t * t * A + t * B + C
    }
    
    func delta(at t: CGFloat) -> CGPoint {
        return 2 * t * A + B
    }
    
    func time(of point: CGPoint) -> CGFloat {
        let xtsqrt = sqrt(B.x * B.x - 4 * A.x * (C.x - point.x))
        let xts = [(-B.x - xtsqrt) / (2 * A.x), (-B.x + xtsqrt) / (2 * A.x)]
        let ytsqrt = sqrt(B.y * B.y - 4 * A.y * (C.y - point.y))
        let yts = [(-B.y + ytsqrt) / (2 * A.y), (-B.y - ytsqrt) / (2 * A.y)]
        var record: CGFloat = 1000000.0
        var holder: CGFloat = 0.0
        for xt in xts {
            for yt in yts {
                let diff = abs(xt - yt)
                if diff < record {
                    record = diff
                    holder = (xt + yt) / 2
                }
            }
        }
        return holder
    }
    
    func normal(positive: Bool, radius: CGFloat) -> NormalArc {
        return NormalArc(A: A, B: B, C: C, positive: positive, radius: radius)
    }
    
    func softened() -> Arc {
        return Arc(origin: origin, outpost: outpost, control: control, intensity: 0.3, thickness: 5.0)
    }
    
    static func +(_ lhs: Arc, _ rhs: CGPoint) -> Arc {
        return Arc(origin: lhs.origin + rhs, outpost: lhs.outpost + rhs, control: lhs.control + rhs, intensity: lhs.intensity, thickness: lhs.thickness)
    }
    
    static func +(_ lhs: Arc, _ rhs: Arc) -> Arc {
        return Arc(A: lhs.A + rhs.A, B: lhs.B + rhs.B, C: lhs.C + rhs.C)
    }
    
    static func *(_ lhs: CGFloat, _ rhs: Arc) -> Arc {
        return Arc(A: lhs * rhs.A, B: lhs * rhs.B, C: lhs * rhs.C)
    }
    
    //Finds the intersection between two lines
    static func ^^(_ first: Arc, _ second: Tangential) -> CGPoint? {
        guard (first.bounds.intersects(second.bounds)) else {
            return nil
        }
        
        for pieceOne in first.tangents {
            for pieceTwo in second.tangents {
                if let intersection = pieceOne ^^ pieceTwo {
                    return intersection
                }
            }
        }
        
        return nil
    }
}

class NormalArc: Tangential {
    lazy var tangents: [Tangent] = {
        return calculateTangents()
    }()
    
    lazy var bounds: CGRect = {
        return calculateBounds()
    }()
    
    var A: CGPoint
    var B: CGPoint
    var C: CGPoint
    
    var positive: Bool
    var radius: CGFloat
    
    init(A: CGPoint, B: CGPoint, C: CGPoint, positive: Bool, radius: CGFloat) {
        self.A = A
        self.B = B
        self.C = C
        self.positive = positive
        self.radius = radius
    }
    
    func at(_ t: CGFloat) -> CGPoint {
        let magnitude = ~(2.0 * t * A + B)
        let normal = radius * ((2.0 * t * A + B) / magnitude).orthogonalize()
        if positive {
            return t * t * A + t * B + C + normal
        }
        else {
            return t * t * A + t * B + C - normal
        }
    }
}
