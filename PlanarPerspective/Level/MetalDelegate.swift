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

protocol BufferSignature {
    associatedtype T
    var type: T.Type { get }
    var count: Int { get }
    var contents: [T] { get }
    var stride: Int { get }
    var index: Int { get }
    var empty: Bool { get }
    var mode: MTLResourceOptions { get }
}

struct ShaderSignature {
    let name: String
    let threads: Int
    let inputs: [any BufferSignature]
    let outputs: [String : any BufferSignature]
}

//Delegate class for compression based in Metal
class MetalDelegate {
    var device: MTLDevice
    var library: MTLLibrary
    var queue: MTLCommandQueue
    var states: [String : MTLComputePipelineState] = [:]
    
    //Initializes delegate with reference to supervisor
    init(level: LevelView) throws {
        //Retreives the default device
        device = MTLCreateSystemDefaultDevice()!
        //Builds a function library from all available metal files
        library = device.makeDefaultLibrary()!
        
        queue = device.makeCommandQueue()!
    }
    
    func buildPipeline(called name: String, bounded potential: Int?) {
        let constants = MTLFunctionConstantValues()
        
        if let bound = potential {
            let up = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<Int>.stride, alignment: MemoryLayout<Int>.alignment)
            up.storeBytes(of: UInt(bound), as: UInt.self)
            let rp = UnsafeRawPointer(up)
            constants.setConstantValue(rp, type: .uint, index: 0)
        }
        
        let function = try! library.makeFunction(name: "cliplines", constantValues: constants)
        states[name] = try! device.makeComputePipelineState(function: function)
    }
    
    func buildBuffer<T: BufferSignature>(_ signature: T) -> MTLBuffer {
        if signature.empty {
            return device.makeBuffer(length: signature.stride * signature.count, options: signature.mode)!
        }
        return device.makeBuffer(bytes: signature.contents, length: signature.stride * signature.count, options: signature.mode)!
    }
    
    func load<T: BufferSignature>(buffer: MTLBuffer, as signature: T) -> [T.T] {
        let pointer = buffer.contents()
        var mutable: [T.T] = []
        
        for i in 0 ..< signature.count {
            let new = pointer.load(fromByteOffset: i * signature.stride, as: signature.type)
            mutable.append(new)
        }
        
        return mutable
    }
    
    func execute(_ signature: ShaderSignature) -> [String : [Any]] {
        let buffer: MTLCommandBuffer
        
        if #available(iOS 14.0, *) {
            let desc = MTLCommandBufferDescriptor()
            desc.errorOptions = .encoderExecutionStatus
            buffer = queue.makeCommandBuffer(descriptor: desc)!
        } else {
            buffer = queue.makeCommandBuffer()!
        }
        
        let state = states[signature.name]!
        
        //Creates transient buffer and encoder for the compute run
        let encoder: MTLComputeCommandEncoder = buffer.makeComputeCommandEncoder()!
        encoder.setComputePipelineState(state)
        
        let width = min(state.maxTotalThreadsPerThreadgroup, signature.threads)
        let gheight = Int((Double(signature.threads) / Double(width)).rounded(.up))
        
        for input in signature.inputs {
            encoder.setBuffer(buildBuffer(input), offset: 0, index: input.index)
        }
        
        var outputBuffers: [String : MTLBuffer] = [:]
        
        for key in signature.outputs.keys {
            let buffer = buildBuffer(signature.outputs[key]!)
            outputBuffers[key] = buffer
            encoder.setBuffer(buffer, offset: 0, index: signature.outputs[key]!.index)
        }
        
        //Dispath the threadgroups with the calculated configuration
        encoder.dispatchThreadgroups(MTLSize(width: gheight, height: 1, depth: 1), threadsPerThreadgroup: MTLSize(width: width, height: 1, depth: 1))
        
        
        //Dispath the threadgroups with the calculated configuration
        encoder.endEncoding()
        
        //Send off for compute pass
        buffer.commit()
        
        
        
        //Wait until computation is completed
        buffer.waitUntilCompleted()
        
        var outputs: [String : [Any]] = [:]
        
        for key in outputBuffers.keys {
            outputs[key] = load(buffer: outputBuffers[key]!, as: signature.outputs[key]!)
        }
        
        return outputs
    }
}
