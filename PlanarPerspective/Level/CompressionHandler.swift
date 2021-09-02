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
    var scope: MTLCaptureScope
    var manager: MTLCaptureManager
    
    //Cache to prevent redundant GPU calls
    var cache: [Transform : [Line]] = [:]
    
    //Initializes delegate with reference to supervisor
    init(level: LevelView) throws {
        //Retreives the default device
        device = MTLCreateSystemDefaultDevice()!
        //Builds a function library from all available metal files
        library = device.makeDefaultLibrary()!
        //Finds function named clip
        let function = library.makeFunction(name: "polygons")!
        //Creates pipeline state
        state = try! device.makeComputePipelineState(function: function)
        queue = device.makeCommandQueue()!
        polys = level.polygons
        //Disturb the data by telling scary stories right before bed.
        polys = polys.map { (polygon) -> Polygon in
            return Polygon(vertices: polygon.vertices.map { (vertex) -> Vertex in
                //...and the stack trace was coming from INSIDE the program.
                return Vertex(x: vertex.x + CGFloat.random(in: -0.1...0.1), y: vertex.y + CGFloat.random(in: -0.1...0.1), z: vertex.z + CGFloat.random(in: -0.1...0.1))
            })
        }
        manager = MTLCaptureManager.shared()
         
        scope = manager.makeCaptureScope(device: device)
        // Add a label if you want to capture it from XCode's debug bar
        scope.label = "Pls debug me"
        // If you want to set this scope as the default debug scope, assign it to MTLCaptureManager's defaultCaptureScope
        manager.defaultCaptureScope = scope
    }
    
    //Compress the polygons using a given transform
    func compress(with transform: Transform) -> [Line] {
        //If there is a cached result, use it
        if let cached = cache[transform] {
            return cached
        }
        
        //Transformed polygons as MetalPolygon wrapper types
        let standards: [MetalPolygon] = polys.map { transform.method($0).harden() }
        
        scope.begin()
        
        let buffer: MTLCommandBuffer
        
        if #available(iOS 14.0, *) {
            let desc = MTLCommandBufferDescriptor()
            desc.errorOptions = .encoderExecutionStatus
            buffer = queue.makeCommandBuffer(descriptor: desc)!
        } else {
            buffer = queue.makeCommandBuffer()!
        }
        
        //Creates transient buffer and encoder for the compute run
        
        let encoder: MTLComputeCommandEncoder = buffer.makeComputeCommandEncoder()!
        encoder.setComputePipelineState(state)
        
        //Builds an input buffer to hold the polygons
        
        let polygons = device.makeBuffer(bytes: standards, length: MemoryLayout<MetalPolygon>.stride * standards.count, options: .storageModeShared)!
        
        
        
        //Compiles list of MetalEdges for clipping
        var edgeslist: [MetalEdge] = []
        var i = 0
        polys.forEach { (poly) in
            edgeslist.append(contentsOf: transform.method(poly).hardedges(id: i))
            i += 1
        }
        
        //Calculates threadgrid parameters
        let width = min(state.maxTotalThreadsPerThreadgroup, edgeslist.count)
        let gheight = Int((Double(edgeslist.count) / Double(width)).rounded(.up))
        let amount = width * gheight
        
        //Builds a buffer to store the edges for clipping
        let edges = try device.makeBuffer(bytes: &edgeslist, length: edgeslist.count * MemoryLayout<MetalEdge>.stride, options: .storageModeShared)!
        
        
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
        
        
        scope.end()
        
        //Wait until computation is completed
        buffer.waitUntilCompleted()
        if #available(iOS 14.0, *) {
            if let error = buffer.error as NSError? {
                print(error)
            }
        }
        
        //Unrefined wrappers to be processed
        var unrefined: [MetalEdge] = []
        var debug: [DebuggeringMetal] = []
        
        //Manually retreives debugs from debug buffer from buffer pointer
        let pointerb = debugBuffer!.contents()
        for i in 0 ..< amount {
            let new = pointerb.load(fromByteOffset: i * MemoryLayout<DebuggeringMetal>.stride, as: DebuggeringMetal.self)
            debug.append(new)
        }
        /*
        //Prints results
        if debug.contains(where: { (debug) -> Bool in
            return debug.point < 100 && debug.point > 0
        }) {
            print("yep")
            /*print(debug.max(by: { (first, second) -> Bool in
                return first.code < second.code
            }))*/
        }*/
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
        
        //Final results are attained by converting wrapper types to normal swift types for return
        let lines = roughs.map { (segment) -> Line in
            return Line(segment)
        }
        
        //print(MemoryLayout<MetalEdge>.stride)
        //print(MemoryLayout<MetalSegment>.stride)
        //print(lines.count)
        //Cache results
        cache[transform] = lines
        
        //Return 'em while your at it
        //print("frame")
        return lines
    }
}
