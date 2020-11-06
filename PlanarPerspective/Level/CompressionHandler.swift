//
//  ExpirimentalCompression.swift
//  PlanarPerspective
//
//  Created by Rylie Anderson on 10/25/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit
import MetalKit

//Delegate class for compression based in Metal
class CompressionHandler {
    //Nessecary Metal types
    var device: MTLDevice
    var library: MTLLibrary
    var queue: MTLCommandQueue
    var state: MTLComputePipelineState
    var polys: [Polygon]
    
    //Cache to prevent redundant GPU calls
    var cache: [Polygon : [Line]] = [:]
    
    //Initializes delegate with reference to supervisor
    init(level: LevelView) throws {
        //Retreives the default device
        device = MTLCreateSystemDefaultDevice()!
        //Builds a function library from all available metal files
        library = device.makeDefaultLibrary()!
        //Finds function named clip
        let function = library.makeFunction(name: "clip")!
        //Creates pipeline state
        state = try! device.makeComputePipelineState(function: function)
        queue = device.makeCommandQueue()!
        polys = level.polygons
    }
    
    //Compress the polygons using a given transform
    func compress(with transform: Transform) -> [Line] {
        //Use test polygon to locat cached results (Transforms aren't hashable as they are actually closures)
        let test = transform(Polygon(vertices: [Vertex(x: 31, y: 14, z: 159), Vertex(x: 27, y: 18, z: 28)]))
        //If there is a cached result, use it
        if let cached = cache[test] {
            return cached
        }
        
        //Transformed polygons as MetalPolygon wrapper types
        let standards: [MetalPolygon] = polys.map { transform($0).harden() }
        
        //Creates transient buffer and encoder for the compute run
        let buffer: MTLCommandBuffer = queue.makeCommandBuffer()!
        let encoder: MTLComputeCommandEncoder = buffer.makeComputeCommandEncoder()!
        encoder.setComputePipelineState(state)
        
        //Builds an input buffer to hold the polygons
        let polygons = device.makeBuffer(bytes: standards, length: MemoryLayout<MetalPolygon>.stride * standards.count, options: .storageModeShared)!
        
        //Compiles list of MetalEdges for clipping
        var edgeslist: [MetalEdge] = []
        polys.forEach { (poly) in
            edgeslist.append(contentsOf: transform(poly).hardedges())
        }
        
        //Calculates threadgrid parameters
        let width = min(state.maxTotalThreadsPerThreadgroup, edgeslist.count)
        let gheight = Int((Double(edgeslist.count) / Double(width)).rounded(.up))
        let amount = width * gheight
        
        //Builds a buffer to store the edges for clipping
        let edges = device.makeBuffer(bytes: &edgeslist, length: amount * MemoryLayout<MetalEdge>.stride, options: .storageModeShared)!
        
        //The parameter bounds (no way to get array length in a metal shader)
        var bounds: SIMD2<UInt32> = SIMD2<UInt32>(UInt32(standards.count), UInt32(edgeslist.count))
        
        //Creates a buffer to store the bounds
        let boundBuffer = device.makeBuffer(bytes: &bounds, length: MemoryLayout<SIMD2<UInt>>.stride, options: .storageModeShared)
        
        //Creates array of blank debug types
        let debugs: [DebuggeringMetal] = [DebuggeringMetal].init(repeating: DebuggeringMetal(), count: amount)
        
        //Creates buffer to store them
        let debugBuffer = device.makeBuffer(bytes: debugs, length: MemoryLayout<DebuggeringMetal>.stride * amount, options: .storageModeShared)
        
        //Encodes the buffers
        encoder.setBuffer(polygons, offset: 0, index: 0)
        encoder.setBuffer(edges, offset: 0, index: 1)
        encoder.setBuffer(debugBuffer, offset: 0, index: 2)
        encoder.setBuffer(boundBuffer, offset: 0, index: 3)
        
        
        //Dispath the threadgroups with the calculated configuration
        encoder.dispatchThreadgroups(MTLSize(width: gheight, height: 1, depth: 1), threadsPerThreadgroup: MTLSize(width: width, height: 1, depth: 1))
        encoder.endEncoding()
        
        //Send off for compute pass
        buffer.commit()
        
        //Wait until computation is completed
        buffer.waitUntilCompleted()
        
        //Unrefined wrappers to be processed
        var unrefined: [MetalEdge] = []
        var debug: [DebuggeringMetal] = []
        
        //Manually retreives debugs from debug buffer from buffer pointer
        let pointerb = debugBuffer!.contents()
        for i in 0 ..< amount {
            let new = pointerb.load(fromByteOffset: i * MemoryLayout<DebuggeringMetal>.stride, as: DebuggeringMetal.self)
            debug.append(new)
        }
        //Prints results
        print(debug)
        
        //Manually retreives function results from edge buffer
        let pointer = edges.contents()
        for i in 0 ..< edgeslist.count {
            let new = pointer.load(fromByteOffset: i * MemoryLayout<MetalEdge>.stride, as: MetalEdge.self)
            unrefined.append(new)
        }
        
        //Array to hold intermediate stage of processing as segment wrappers are retreived from edges
        var roughs: [MetalSegment] = []
        unrefined.forEach { (edge) in
            for i in 0 ..< edge.count {
                switch i {
                case 0:
                    roughs.append(edge.segments.0)
                case 1:
                    roughs.append(edge.segments.0)
                case 2:
                    roughs.append(edge.segments.0)
                case 3:
                    roughs.append(edge.segments.0)
                case 4:
                    roughs.append(edge.segments.0)
                case 5:
                    roughs.append(edge.segments.0)
                case 6:
                    roughs.append(edge.segments.0)
                case 7:
                    roughs.append(edge.segments.0)
                case 8:
                    roughs.append(edge.segments.0)
                case 9:
                    roughs.append(edge.segments.0)
                case 10:
                    roughs.append(edge.segments.0)
                case 11:
                    roughs.append(edge.segments.0)
                case 12:
                    roughs.append(edge.segments.0)
                case 13:
                    roughs.append(edge.segments.0)
                case 14:
                    roughs.append(edge.segments.0)
                case 15:
                    roughs.append(edge.segments.0)
                case 16:
                    roughs.append(edge.segments.0)
                case 17:
                    roughs.append(edge.segments.0)
                case 18:
                    roughs.append(edge.segments.0)
                case 19:
                    roughs.append(edge.segments.0)
                default:
                    break;
                }
            }
        }
        
        //Final results are attained by converting wrapper types to normal swift types for return
        let lines = roughs.map { (segment) -> Line in
            return Line(segment)
        }
        
        //Cache results
        cache[test] = lines
        
        //Return 'em while your at it
        return lines
    }
}
