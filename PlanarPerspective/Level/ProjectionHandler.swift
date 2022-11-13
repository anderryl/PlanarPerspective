//
//  ProjectionHandler.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 6/9/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit

//Utility delegate accessed only statically for functions
class ProjectionHandler {
    
    //Creates a Transform factory from a transition
//    static func __transformation(from one: Plane, to two: Plane) -> (rotation: CGFloat, factory: TransformFactory) {
//        return
//    }
    
    //Creates a Transform factory from a transition
    static func transformation(from one: Plane, to two: Plane) -> (rotation: CGFloat, factory: TransformFactory) {
        let first: (_ polygon: Polygon) -> Polygon = component(of: one).method
        //let second: Transform = component(of: two)
        let comp = partialComponent(from: one, to: two)
        let second: (_ polygon: Polygon) -> Polygon = comp.transform
        func transform(phase: CGFloat) -> Transform {
            let pi = CGFloat(3.14159 / 2.0)
            let comp = pi * phase
            return Transform(method: { (polygon: Polygon) -> Polygon in
                var vertices: [Vertex] = []
                let one = first(polygon)
                let two = second(polygon)
                for i in 0 ..< polygon.vertices.count {
                    vertices.append(Vertex(x: cos(comp) * one.vertices[i].x + sin(comp) * two.vertices[i].x, y: cos(comp) * one.vertices[i].y + sin(comp) * two.vertices[i].y, z: cos(comp) * one.vertices[i].z + sin(comp) * two.vertices[i].z))
                }
                return Polygon(vertices: vertices)
            }, from: one, to: two, prog: phase)
        }
        return (rotation: comp.rotation, factory: transform(phase:))
    }
    
    //Finds the rotated transform of a transition state
    static func partialComponent(from first: Plane, to second: Plane) -> (rotation: CGFloat, transform: (_ polygon: Polygon) -> Polygon) {
        //Rotates a transform counterclockwise
        func counter(_ transform: @escaping (_ polygon: Polygon) -> Polygon) -> (rotation: CGFloat, transform: (_ polygon: Polygon) -> Polygon) {
            func rotation(polygon: Polygon) -> Polygon {
                let original = transform(polygon)
                var vertices: [Vertex] = []
                for vertex in original.vertices {
                    vertices.append(Vertex(x: -vertex.y, y: vertex.x, z: vertex.z))
                }
                return Polygon(vertices: vertices)
            }
            return (rotation: -3.14159 / 2, transform: rotation(polygon:))
        }
        
        //Rotates a transform clockwise
        func clockwise(_ transform: @escaping (_ polygon: Polygon) -> Polygon) -> (rotation: CGFloat, transform: (_ polygon: Polygon) -> Polygon) {
            func rotation(polygon: Polygon) -> Polygon {
                let original = transform(polygon)
                var vertices: [Vertex] = []
                for vertex in original.vertices {
                    vertices.append(Vertex(x: vertex.y, y: -vertex.x, z: vertex.z))
                }
                return Polygon(vertices: vertices)
            }
            return (rotation: 3.14159 / 2, transform: rotation(polygon:))
        }
        
        //Rotates a transform a half-revolution
        func flip(_ transform: @escaping (_ polygon: Polygon) -> Polygon) -> (rotation: CGFloat, transform: (_ polygon: Polygon) -> Polygon) {
            func rotation(polygon: Polygon) -> Polygon {
                let original = transform(polygon)
                var vertices: [Vertex] = []
                for vertex in original.vertices {
                    vertices.append(Vertex(x: -vertex.x, y: -vertex.y, z: vertex.z))
                }
                return Polygon(vertices: vertices)
            }
            return (rotation: 3.14159, rotation(polygon:))
        }
        
        //The natural transform of the destination plane
        let comp = component(of: second)
        
        //Decides on rotation based on plane combination
        switch second {
        case .TOP:
            switch first {
            case .LEFT:
                return clockwise(comp.method)
            case .RIGHT:
                return counter(comp.method)
            case .BACK:
                return flip(comp.method)
            default:
                return (rotation: 0, transform: comp.method)
            }
        case .BOTTOM:
            switch first {
            case .LEFT:
                return counter(comp.method)
            case .RIGHT:
                return clockwise(comp.method)
            case .BACK:
                return flip(comp.method)
            default:
                return (rotation: 0, transform: comp.method)
            }
        case .LEFT:
            switch first {
            case .TOP:
                return counter(comp.method)
            case .BOTTOM:
                return clockwise(comp.method)
            default:
                return (rotation: 0, transform: comp.method)
            }
        case .RIGHT:
            switch first {
            case .TOP:
                return counter(comp.method)
            case .BOTTOM:
                return clockwise(comp.method)
            default:
                return (rotation: 0, transform: comp.method)
            }
        case .FRONT:
            return (rotation: 0, transform: comp.method)
        case .BACK:
            switch first {
            case .TOP:
                return flip(comp.method)
            case .BOTTOM:
                return flip(comp.method)
            default:
                return (rotation: 0, transform: comp.method)
            }
        }
    }
    
    //Finds the transform for any given plane
    static func component(of plane: Plane) -> Transform {
        switch plane {
        case .TOP:
            func transform(_ polygon: Polygon) -> Polygon {
                var vertices: [Vertex] = []
                for vertex in polygon.vertices {
                    let new = Vertex(x: vertex.x, y: vertex.z, z: -vertex.y)
                    vertices.append(new)
                }
                return Polygon(vertices: vertices)
            }
            return Transform(method: transform(_:), from: plane, to: plane, prog: 0)
            
        case .BOTTOM:
            func transform(_ polygon: Polygon) -> Polygon {
                var vertices: [Vertex] = []
                for vertex in polygon.vertices {
                    let new = Vertex(x: vertex.x, y: -vertex.z, z: vertex.y)
                    vertices.append(new)
                }
                return Polygon(vertices: vertices)
            }
            return Transform(method: transform(_:), from: plane, to: plane, prog: 0)
            
        case .LEFT:
            func transform(_ polygon: Polygon) -> Polygon {
                var vertices: [Vertex] = []
                for vertex in polygon.vertices {
                    let new = Vertex(x: -vertex.z, y: vertex.y, z: vertex.x)
                    vertices.append(new)
                }
                return Polygon(vertices: vertices)
            }
            return Transform(method: transform(_:), from: plane, to: plane, prog: 0)
        case .RIGHT:
            func transform(_ polygon: Polygon) -> Polygon {
                var vertices: [Vertex] = []
                for vertex in polygon.vertices {
                    let new = Vertex(x: vertex.z, y: vertex.y, z: -vertex.x)
                    vertices.append(new)
                }
                return Polygon(vertices: vertices)
            }
            return Transform(method: transform(_:), from: plane, to: plane, prog: 0)
        case .FRONT:
            func transform(_ polygon: Polygon) -> Polygon {
                var vertices: [Vertex] = []
                for vertex in polygon.vertices {
                    let new = Vertex(x: vertex.x, y: vertex.y, z: vertex.z)
                    vertices.append(new)
                }
                return Polygon(vertices: vertices)
            }
            return Transform(method: transform(_:), from: plane, to: plane, prog: 0)
        case .BACK:
            func transform(_ polygon: Polygon) -> Polygon {
                var vertices: [Vertex] = []
                for vertex in polygon.vertices {
                    let new = Vertex(x: -vertex.x, y: vertex.y, z: -vertex.z)
                    vertices.append(new)
                }
                return Polygon(vertices: vertices)
            }
            return Transform(method: transform(_:), from: plane, to: plane, prog: 0)
        }
    }
    
    //Compresses a three dimensional vertex into two dimensional point on a given plane
    static func compress(vertex: Vertex, onto plane: Plane) -> Vertex {
        switch plane {
        case .TOP:
            let new = Vertex(x: vertex.x, y: vertex.z, z: -vertex.y)
            return new
        case .BOTTOM:
            let new = Vertex(x: vertex.x, y: -vertex.z, z: vertex.y)
            return new
        case .LEFT:
            let new = Vertex(x: -vertex.z, y: vertex.y, z: vertex.x)
            return new
        case .RIGHT:
            let new = Vertex(x: vertex.z, y: vertex.y, z: -vertex.x)
            return new
        case .FRONT:
            let new = Vertex(x: vertex.x, y: vertex.y, z: vertex.z)
            return new
        case .BACK:
            let new = Vertex(x: -vertex.x, y: vertex.y, z: -vertex.z)
            return new
        }
    }
    
    //Unfolds a two dimensional from a given point point into the outstanding coordinate of a given position
    static func unfold(point: CGPoint, onto position: Position, from plane: Plane) -> Vertex {
        switch plane {
        case .TOP:
            return Vertex(x: point.x, y: position.y, z: point.y)
        case .BOTTOM:
            return Vertex(x: point.x, y: position.y, z: -point.y)
        case .LEFT:
            return Vertex(x: position.x, y: point.y, z: -point.x)
        case .RIGHT:
            return Vertex(x: position.x, y: point.y, z: point.x)
        case .FRONT:
            return Vertex(x: point.x, y: point.y, z: position.z)
        case .BACK:
            return Vertex(x: -point.x, y: point.y, z: position.z)
        }
    }
}
