//
//  ProjectionHandler.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 6/9/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit

infix operator ~~

typealias MatrixTransform = [[CGFloat]]

typealias MatrixTransformFactory = (_ theta: CGFloat) -> MatrixTransform

enum Axis {
    case X
    case Y
    case Z
}

extension MatrixTransform {
    static var identity: MatrixTransform = [
        [1, 0, 0],
        [0, 1, 0],
        [0, 0, 1]
    ]
    
    static func *(_ lhs: MatrixTransform, _ rhs: MatrixTransform) -> MatrixTransform {
        var ret: MatrixTransform = []
        for r in 0 ... 2 {
            var prog: [CGFloat] = []
            for c in 0 ... 2 {
                prog.append(lhs[r][0] * rhs[0][c] + lhs[r][1] * rhs[1][c] + lhs[r][2] * rhs[2][c])
            }
            ret.append(prog)
        }
        assert(ret.count == 3 && ret[0].count == 3)
        return ret
    }
    
    static func *(_ rhs: MatrixTransform, _ lhs: Vertex) -> Vertex {
        return Vertex(
            x: rhs[0][0] * lhs.x + rhs[0][1] * lhs.y + rhs[0][2] * lhs.z,
            y: rhs[1][0] * lhs.x + rhs[1][1] * lhs.y + rhs[1][2] * lhs.z,
            z: rhs[2][0] * lhs.x + rhs[2][1] * lhs.y + rhs[2][2] * lhs.z
        )
    }
    
    static func *(_ rhs: MatrixTransform, _ lhs: CGPoint) -> CGPoint {
        return CGPoint(
            x: rhs[0][0] * lhs.x + rhs[0][1] * lhs.y,
            y: rhs[1][0] * lhs.x + rhs[1][1] * lhs.y
        )
    }
    
    static func *(_ lhs: MatrixTransform, _ rhs: Line) -> Line {
        return Line(origin: lhs * rhs.origin, outpost: lhs * rhs.outpost, intensity: rhs.intensity, thickness: rhs.thickness)
    }
    
    static func *(_ rhs: MatrixTransform, _ lhs: Polygon) -> Polygon {
        return Polygon(vertices: lhs.vertices.map({rhs * $0}))
    }
    
    static func *(_ rhs: MatrixTransform, _ lhs: Region) -> Region {
        return Region(origin: rhs * lhs.origin, outpost: rhs * lhs.outpost)
    }
    
    static func ==(_ rhs: MatrixTransform, _ lhs: MatrixTransform) -> Bool {
        for i in 0 ..< 3 {
            for j in 0 ..< 3 {
                if rhs[i][j] != lhs[i][j] {
                    return false
                }
            }
        }
        return true
    }
    
    static func ~~(_ rhs: MatrixTransform, _ lhs: MatrixTransform) -> Bool {
        for i in 0 ..< 3 {
            if rhs[i][2] != lhs[i][2] {
                return false
            }
        }
        
        for j in 0 ..< 3 {
            if rhs[2][j] != lhs[2][j] {
                return false
            }
        }
        return true
    }
    
    func normalized() -> MatrixTransform {
        return map { $0.map { round($0) } }
    }
    
    func inverted() -> MatrixTransform {
        var ret = MatrixTransform.identity
        for r in 0 ... 2 {
            for c in 0 ... 2 {
                ret[c][r] = self[r][c]
            }
        }
        return ret
    }
    
    func rotate(axis: Axis, reverse: Bool) -> MatrixTransformFactory {
        var mult = 3.14159 / 2
        if reverse {
            mult = -3.14159 / 2
        }
        switch axis {
        case .X:
            return { (_ rtheta: CGFloat) -> MatrixTransform in
                let theta = rtheta * mult
                return [
                    [1, 0, 0],
                    [0, cos(theta), -sin(theta)],
                    [0, sin(theta), cos(theta)]
                ] * self
            }
        case .Y:
            return { (_ rtheta: CGFloat) -> MatrixTransform in
                let theta = rtheta * mult
                return [
                    [cos(theta), 0, sin(theta)],
                    [0, 1, 0],
                    [-sin(theta), 0, cos(theta)]
                ] * self
            }
        case .Z:
            return { (_ rtheta: CGFloat) -> MatrixTransform in
                let theta = rtheta * mult
                return [
                    [cos(theta), -sin(theta), 0],
                    [sin(theta), cos(theta), 0],
                    [0, 0, 1]
                ] * self
            }
        }
    }
    
    func slide(in direction: Direction) -> MatrixTransformFactory {
        switch direction {
        case .UP:
            return rotate(axis: .X, reverse: false)
        case .DOWN:
            return rotate(axis: .X, reverse: true)
        case .LEFT:
            return rotate(axis: .Y, reverse: false)
        case .RIGHT:
            return rotate(axis: .Y, reverse: true)
        }
    }
    
    func twist(in wise: Rotation) -> MatrixTransformFactory {
        switch wise {
        case .CLOCKWISE:
            return rotate(axis: .Z, reverse: true)
        case .COUNTER:
            return rotate(axis: .Z, reverse: false)
        }
    }
    
    func unfold(point: CGPoint, onto position: Position) -> Position {
        return inverted() * Position(x: point.x, y: point.y, z: (self * position).z)
    }
    
    func hash() -> Int {
        var into = 0
        for r in 0 ..< 3 {
            into = (Int(bitPattern: self[r][2].bitPattern)^into)^(into<<1) + 1
        }
        for c in 0 ..< 2 {
            into = (Int(bitPattern: self[2][c].bitPattern)^into)^(into<<1) + 1
        }
        return into
    }
}
