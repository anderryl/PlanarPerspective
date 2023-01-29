//
//  CompressionHandler.swift
//  PlanarPerspective
//
//  Created by Rylie Anderson on 1/28/23.
//  Copyright © 2023 Anderson, Todd W. All rights reserved.
//

import Foundation
import Metal

struct PolygonSignature: BufferSignature {
    var type: MetalPolygon.Type = MetalPolygon.self
    var count: Int
    var contents: [MetalPolygon]
    var stride: Int = MemoryLayout<MetalPolygon>.stride
    var index: Int
    var empty: Bool = false
    var mode: MTLResourceOptions
}

struct EdgeSignature: BufferSignature {
    var type: MetalEdge.Type = MetalEdge.self
    var count: Int
    var contents: [MetalEdge]
    var stride: Int = MemoryLayout<MetalEdge>.stride
    var index: Int
    var empty: Bool = false
    var mode: MTLResourceOptions
}

struct ClipperResourceSignature: BufferSignature {
    var type: ClipperResource.Type = ClipperResource.self
    var count: Int
    var contents: [ClipperResource]
    var stride: Int = MemoryLayout<ClipperResource>.stride
    var index: Int
    var empty: Bool = true
    var mode: MTLResourceOptions
}

class CompressionHandler {
    var polygons: [Polygon]
    
    //Cache to prevent redundant GPU calls
    var cache: [Int : [(transform: MatrixTransform, lines: [Arc])]] = [:]
    
    unowned var metal: MetalDelegate
    
    init(polygons: [Polygon], metal: MetalDelegate) {
        self.metal = metal
        
        //Disturb the data by telling scary stories right before bed.
        let disturbance: CGFloat = 0.1
        let range = -disturbance ... disturbance
        self.polygons = polygons.map { (polygon) -> Polygon in
            return Polygon(curves: polygon.curves.map { (curve) -> Curve in
                //...and the stack trace was coming from INSIDE the program.
                return Curve(origin: curve.origin + Vertex.random(in: range), outpost: curve.outpost + Vertex.random(in: range), control: curve.control + Vertex.random(in: range), thickness: curve.thickness)
            })
        }
        
        metal.buildPipeline(called: "cliplines", bounded: polygons.count)
    }
    
    func compress(transform: MatrixTransform) -> [Arc] {
        if let cached = retrieve(transform: transform) {
            return cached
        }
        let results = compute(with: transform)
        place(transform: transform, arcs: results)
        return results
    }
    
    //Retrieve computed arcs from cache
    func retrieve(transform: MatrixTransform) -> [Arc]? {
        //If there is a cached result, use it
        let hash = transform.hash()
        if let cached = cache[hash] {
            for item in cached {
                if item.transform == transform {
                    return item.lines
                }
            }
            for item in cached {
                //God, I love writing unmaintainable code
                if item.transform ~~ transform {
                    let res = item.lines.map { transform * (item.transform.inverted() * $0) }
                    if let cohashes = cache[hash] {
                        cache[transform.hash()] = cohashes + [(transform: transform, lines: res)]
                    }
                    else {
                        cache[hash] = [(transform: transform, lines: res)]
                    }
                    return res
                }
            }
        }
        return nil
    }
    
    func place(transform: MatrixTransform, arcs: [Arc]) {
        //Cache results
        if let others = cache[transform.hash()] {
            cache[transform.hash()] = others + [(transform: transform, lines: arcs)]
        }
        else {
            cache[transform.hash()] = [(transform: transform, lines: arcs)]
        }
    }
    
    func compute(with transform: MatrixTransform) -> [Arc] {
        //return polygons.map { transform * $0 }.reduce([]) { $0 + $1.arcs() }
        
        
        //Transformed polygons as MetalPolygon wrapper types
        let standards: [MetalPolygon] = polygons.map { (transform * $0).harden() }
        
        var edges: [MetalEdge] = []
        var i = 0
        polygons.forEach { (poly) in
            edges.append(contentsOf: (transform * poly).hardedges(id: i))
            i += 1
        }
        
        let signature = ShaderSignature(
            name: "cliplines",
            threads: edges.count,
            inputs: [
                PolygonSignature(
                    count: standards.count,
                    contents: standards,
                    index: 0,
                    mode: .storageModeShared
                ),
                ClipperResourceSignature(
                    count: edges.count,
                    contents: [],
                    stride: MemoryLayout<ClipperResource>.stride,
                    index: 2,
                    mode: .storageModePrivate
                ),
            ],
            outputs: [
                "edges" : EdgeSignature(
                    count: edges.count,
                    contents: edges,
                    stride: MemoryLayout<MetalEdge>.stride,
                    index: 1,
                    mode: .storageModeShared
                )
            ]
        )
        
        //Unrefined wrappers to be processed
        var unrefined: [MetalEdge] = metal.execute(signature)["edges"]! as! [MetalEdge]
        
        //Array to hold intermediate stage of processing as segment wrappers are retreived from edges
        var roughs: [MetalSegment] = []
        unrefined.forEach { (edge) in
            for i in 0 ..< edge.count {
                switch i {
                case 0:
                    roughs.append(edge.segments.0)
                case 1:
                    roughs.append(edge.segments.1)
                case 2:
                    roughs.append(edge.segments.2)
                case 3:
                    roughs.append(edge.segments.3)
                case 4:
                    roughs.append(edge.segments.4)
                case 5:
                    roughs.append(edge.segments.5)
                case 6:
                    roughs.append(edge.segments.6)
                case 7:
                    roughs.append(edge.segments.7)
                case 8:
                    roughs.append(edge.segments.8)
                case 9:
                    roughs.append(edge.segments.9)
                case 10:
                    roughs.append(edge.segments.10)
                case 11:
                    roughs.append(edge.segments.11)
                case 12:
                    roughs.append(edge.segments.12)
                case 13:
                    roughs.append(edge.segments.13)
                case 14:
                    roughs.append(edge.segments.14)
                case 15:
                    roughs.append(edge.segments.15)
                case 16:
                    roughs.append(edge.segments.16)
                case 17:
                    roughs.append(edge.segments.17)
                case 18:
                    roughs.append(edge.segments.18)
                case 19:
                    roughs.append(edge.segments.19)
                default:
                    break;
                }
            }
        }
        
        let lines = roughs.map { Arc($0) }
        
        return lines
    }
}
