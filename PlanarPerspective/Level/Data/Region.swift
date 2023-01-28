//
//  Region.swift
//  PlanarPerspective
//
//  Created by Rylie Anderson on 11/25/22.
//  Copyright © 2022 Anderson, Todd W. All rights reserved.
//

import Foundation
import CoreGraphics

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
    func flatten(transform: MatrixTransform) -> Polygon {
        
        let vertices = points.map {transform * $0}

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
        let raw = vertices.map { (angle: sweep(center: center, point: $0), vert: $0) }.sorted { $0.angle > $1.angle }
        var sorted = raw.map { $0.vert }
        var removes: [Int] = []

        func hits(_ first: Arc, _ second: Arc) -> Bool {
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
            if hits(Arc(origin: center.flatten(), outpost: current.flatten(), control: (0.5 * (center + current)).flatten(), thickness: 0), Arc(origin: before.flatten(), outpost: after.flatten(), control: (0.5 * (before + after)).flatten(), thickness: 0)) {
                removes.append(i)
            }
        }

        for i in removes.sorted().reversed() {
            sorted.remove(at: i)
        }
        
        var curves: [Curve] = []
        
        for i in 0 ..< sorted.count {
            let origin = sorted[i]
            let outpost = sorted[i + 1 == sorted.count ? 0 : i + 1]
            curves.append(Curve(origin: origin, outpost: outpost, control: (0.5 * (origin + outpost)), thickness: 0))
        }

        return Polygon(curves: curves)
    }
    
    init(origin: Vertex, outpost: Vertex) {
        self.origin = origin
        self.outpost = outpost
    }
}
