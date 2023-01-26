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
    var first: Bool = true
    
    //Cache to prevent redundant GPU calls
    var cache: [Int : [(transform: MatrixTransform, lines: [Arc])]] = [:]
    var mapping: [TransitionState : Int] = [:]
    var cardinals: [MatrixTransform]
    
    //Initializes delegate with reference to supervisor
    init(level: LevelView) throws {
        //Retreives the default device
        device = MTLCreateSystemDefaultDevice()!
        //Builds a function library from all available metal files
        library = device.makeDefaultLibrary()!
        
        //Finds function named clip
        //let function = library.makeFunction(name: "cliplines")!
        let constants = MTLFunctionConstantValues()
        let up = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<Int>.stride, alignment: MemoryLayout<Int>.alignment)
        up.storeBytes(of: UInt(level.polygons.count), as: UInt.self)
        let rp = UnsafeRawPointer(up)
        constants.setConstantValue(rp, type: .uint, index: 0)
        let function = try! library.makeFunction(name: "cliplines", constantValues: constants)
        
        //Creates pipeline state
        state = try! device.makeComputePipelineState(function: function)
        
        queue = device.makeCommandQueue()!
        polys = level.polygons
        //Disturb the data by telling scary stories right before bed.
        let disturbance: CGFloat = 0.1
        let range = -disturbance ... disturbance
        polys = polys.map { (polygon) -> Polygon in
            return Polygon(curves: polygon.curves.map { (curve) -> Curve in
                //...and the stack trace was coming from INSIDE the program.
                return Curve(origin: curve.origin + Vertex.random(in: range), outpost: curve.outpost + Vertex.random(in: range), control: curve.control + Vertex.random(in: range), thickness: curve.thickness)
            })
        }
        manager = MTLCaptureManager.shared()
        
        let captureDescriptor = MTLCaptureDescriptor()
        captureDescriptor.captureObject = self.device
        captureDescriptor.destination = .developerTools
        if #available(iOS 16.0, *) {
            captureDescriptor.outputURL = .currentDirectory()
        } else {
            // Fallback on earlier versions
        }
         
        scope = manager.makeCaptureScope(device: device)
        // Add a label if you want to capture it from XCode's debug bar
        scope.label = "Pls debug me"
        // If you want to set this scope as the default debug scope, assign it to MTLCaptureManager's defaultCaptureScope
        manager.defaultCaptureScope = scope
        
        cardinals = [MatrixTransform.identity]
        cardinals.append(contentsOf: ([1.0, 2.0 ,3.0] as [CGFloat]).map({MatrixTransform.identity.slide(in: .RIGHT)($0)}))
        cardinals.append(contentsOf: ([1.0, 3.0] as [CGFloat]).map({MatrixTransform.identity.slide(in: .UP)($0)}))
    }
    
    func preload(transform: MatrixTransform, length: Int) {
        let map: [TransitionState] = ([.DOWN, .UP, .LEFT, .RIGHT] as [Direction]).map({ direction in
            let factory = transform.slide(in: direction)
            let state = TransitionState(source: transform, destination: factory(1.0), factory: factory, progress: 0, length: length)
            return state.progressed(to: mapping[state] ?? 0)
        })
        let thinnest = map.max(by: {($1.length - $1.progress) > ($0.length - $0.progress)})!
        guard thinnest.progress < thinnest.length else {
            cardinals.removeAll(where: {$0 ~~ transform})
            guard cardinals.count > 0 else {
                return
            }
            return preload(transform: cardinals.last!, length: length)
        }
        let next = thinnest.factory(CGFloat(thinnest.progress + 1) / CGFloat(thinnest.length))
        guard retrieve(transform: next) == nil else {
            mapping[thinnest] = thinnest.progress + 1
            return preload(transform: transform, length: length)
        }
        let results = compute(with: next)
        place(transform: next, arcs: results)
        mapping[thinnest] = thinnest.progress + 1
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
    
    //Compress the polygons using a given transform
    func compute(with transform: MatrixTransform) -> [Arc] {
        
        //return polys.map { transform * $0 }.reduce([]) { $0 + $1.arcs() }
        
        
        //Transformed polygons as MetalPolygon wrapper types
        let standards: [MetalPolygon] = polys.map { (transform * $0).harden() }
        
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
            edgeslist.append(contentsOf: (transform * poly).hardedges(id: i))
            i += 1
        }

        //Calculates threadgrid parameters
        let width = min(state.maxTotalThreadsPerThreadgroup, edgeslist.count)
        let gheight = Int((Double(edgeslist.count) / Double(width)).rounded(.up))
        let amount = width * gheight

        //Builds a buffer to store the edges for clipping
        let edges = device.makeBuffer(bytes: &edgeslist, length: edgeslist.count * MemoryLayout<MetalEdge>.stride, options: .storageModeShared)!
        
        let resources = device.makeBuffer(length: amount * MemoryLayout<ThreadResource>.stride, options: .storageModePrivate)
        
        encoder.setBuffer(polygons, offset: 0, index: 0)
        encoder.setBuffer(edges, offset: 0, index: 1)
        encoder.setBuffer(resources, offset: 0, index: 2)
        

        //Dispath the threadgroups with the calculated configuration
        encoder.dispatchThreadgroups(MTLSize(width: gheight, height: 1, depth: 1), threadsPerThreadgroup: MTLSize(width: width, height: 1, depth: 1))
        
        
        //Dispath the threadgroups with the calculated configuration
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
        let lines = roughs.map { Arc($0) }
        
        return lines
    }
}
