//
//  Polygon.swift
//  PlanarPerspective
//
//  Created by Rylie Anderson on 11/25/22.
//  Copyright © 2022 Anderson, Todd W. All rights reserved.
//

import Foundation
import CoreGraphics

//Represents an in-game polygon
struct Polygon: Codable, Hashable {
    
    var curves: [Curve]
    
    init(curves: [Curve]) {
        self.curves = curves
    }
    
    //Retreives the two dimensional lines that make up the edge of the polygons
    func arcs() -> [Arc] {
        return curves.map { $0.flatten() }
    }
    
    func restrain(position: CGPoint, frame: CGRect) -> CGPoint {
        //let flattened: [CGPoint] = flatten(transform: transform).vertices.map { $0.flatten() }
        let flattened: [CGPoint] = curves.map { $0.origin.flatten() }
        
        let ymax = flattened.max(by: { $0.y < $1.y })!.y -  frame.height / 2
        let ymin = flattened.min(by: { $0.y < $1.y })!.y +  frame.height / 2
        let xmax = flattened.max(by: { $0.x < $1.x })!.x - frame.width / 2
        let xmin = flattened.min(by: { $0.x < $1.x })!.x + frame.width / 2
        
        let y = min(max(ymin, position.y), ymax)
        let x = min(max(xmin, position.x), xmax)
        
        return CGPoint(x: x, y: y)
    }
    
    func applying(_ transform: CGAffineTransform) -> Polygon {
        return Polygon(curves: self.curves.map { $0.applying(transform) })
    }
    
    //Converts to C++ wrapper type for use in Metal compression shader
    //VERY VERY MESSY
    func harden() -> MetalPolygon {
        var verts = (MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex(), MetalVertex())
        for i in 0 ..< curves.count {
            let a = curves[i].origin.harden()
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
        return MetalPolygon(vertices: verts, count: Int32(curves.count))
    }
    
    //Retreives the edges as MetalEdge wrapper types
    func hardedges(id: Int) -> [MetalEdge] {
        return curves.map { $0.harden(id) }
    }
    
    //Initialize from a MetalPolygon wrapper type
    init(_ metal: MetalPolygon) {
        var vertices: [Vertex] = []
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
        self.curves = []
        for i in 0 ..< vertices.count {
            curves.append(Curve(origin: vertices[i], outpost: vertices[i + 1 == vertices.count ? 0 : i + 1], thickness: 1))
        }
    }
}
