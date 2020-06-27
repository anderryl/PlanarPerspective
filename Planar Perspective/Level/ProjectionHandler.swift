//
//  ProjectionHandler.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 6/9/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit

class ProjectionHandler {
    
    static func transformation(from one: Plane, to two: Plane) -> (rotation: CGFloat, factory: TransformFactory) {
        let first: Transform = component(of: one)
        //let second: Transform = component(of: two)
        let comp = partialComponent(from: one, to: two)
        let second: Transform = comp.transform
        func transform(phase: CGFloat) -> Transform {
            let pi = CGFloat(3.14159 / 2.0)
            let comp = pi * phase
            return { (polygon: Polygon) -> Polygon in
                var vertices: [Vertex] = []
                let one = first(polygon)
                let two = second(polygon)
                for i in 0 ..< polygon.vertices.count {
                    vertices.append(Vertex(x: cos(comp) * one.vertices[i].x + sin(comp) * two.vertices[i].x, y: cos(comp) * one.vertices[i].y + sin(comp) * two.vertices[i].y, z: cos(comp) * one.vertices[i].z + sin(comp) * two.vertices[i].z))
                }
                return Polygon(vertices: vertices)
            }
        }
        return (rotation: comp.rotation, factory: transform(phase:))
    }
    
    static func partialComponent(from first: Plane, to second: Plane) -> (rotation: CGFloat, transform: Transform) {
        func counter(_ transform: @escaping Transform) -> (rotation: CGFloat, transform: Transform) {
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
        func clockwise(_ transform: @escaping Transform) -> (rotation: CGFloat, transform: Transform) {
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
        
        func flip(_ transform: @escaping Transform) -> (rotation: CGFloat, transform: Transform) {
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
        let comp = component(of: second)
        switch second {
        case .TOP:
            switch first {
            case .LEFT:
                return clockwise(comp)
            case .RIGHT:
                return counter(comp)
            case .BACK:
                return flip(comp)
            default:
                return (rotation: 0, transform: comp)
            }
        case .BOTTOM:
            switch first {
            case .LEFT:
                return counter(comp)
            case .RIGHT:
                return clockwise(comp)
            case .BACK:
                return flip(comp)
            default:
                return (rotation: 0, transform: comp)
            }
        case .LEFT:
            switch first {
            case .TOP:
                return counter(comp)
            case .BOTTOM:
                return clockwise(comp)
            default:
                return (rotation: 0, transform: comp)
            }
        case .RIGHT:
            switch first {
            case .TOP:
                return counter(comp)
            case .BOTTOM:
                return clockwise(comp)
            default:
                return (rotation: 0, transform: comp)
            }
        case .FRONT:
            return (rotation: 0, transform: comp)
        case .BACK:
            switch first {
            case .TOP:
                return flip(comp)
            case .BOTTOM:
                return flip(comp)
            default:
                return (rotation: 0, transform: comp)
            }
        }
    }
    
    static func component(of plane: Plane) -> Transform {
        switch plane {
        case .TOP:
            func transform(_ polygon: Polygon) -> Polygon {
                var vertices: [Vertex] = []
                for vertex in polygon.vertices {
                    let new = Vertex(x: vertex.x, y: vertex.z, z: vertex.y)
                    vertices.append(new)
                }
                return Polygon(vertices: vertices)
            }
            return transform
        case .BOTTOM:
            func transform(_ polygon: Polygon) -> Polygon {
                var vertices: [Vertex] = []
                for vertex in polygon.vertices {
                    let new = Vertex(x: vertex.x, y: -vertex.z, z: -vertex.y)
                    vertices.append(new)
                }
                return Polygon(vertices: vertices)
            }
            return transform
        case .LEFT:
            func transform(_ polygon: Polygon) -> Polygon {
                var vertices: [Vertex] = []
                for vertex in polygon.vertices {
                    let new = Vertex(x: -vertex.z, y: vertex.y, z: vertex.x)
                    vertices.append(new)
                }
                return Polygon(vertices: vertices)
            }
            return transform
        case .RIGHT:
            func transform(_ polygon: Polygon) -> Polygon {
                var vertices: [Vertex] = []
                for vertex in polygon.vertices {
                    let new = Vertex(x: vertex.z, y: vertex.y, z: -vertex.x)
                    vertices.append(new)
                }
                return Polygon(vertices: vertices)
            }
            return transform
        case .FRONT:
            func transform(_ polygon: Polygon) -> Polygon {
                var vertices: [Vertex] = []
                for vertex in polygon.vertices {
                    let new = Vertex(x: vertex.x, y: vertex.y, z: vertex.z)
                    vertices.append(new)
                }
                return Polygon(vertices: vertices)
            }
            return transform
        case .BACK:
            func transform(_ polygon: Polygon) -> Polygon {
                var vertices: [Vertex] = []
                for vertex in polygon.vertices {
                    let new = Vertex(x: -vertex.x, y: vertex.y, z: -vertex.z)
                    vertices.append(new)
                }
                return Polygon(vertices: vertices)
            }
            return transform
        }
    }
    
    static func compress(vertex: Vertex, onto plane: Plane) -> Vertex {
        switch plane {
        case .TOP:
            let new = Vertex(x: vertex.x, y: vertex.z, z: vertex.y)
            return new
        case .BOTTOM:
            let new = Vertex(x: vertex.x, y: -vertex.z, z: -vertex.y)
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
