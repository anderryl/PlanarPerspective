//
//  CollisionHandler.swift
//  PlanarPerspective
//
//  Created by Rylie Anderson on 1/29/23.
//  Copyright © 2023 Anderson, Todd W. All rights reserved.
//

import Foundation
import Metal

struct TangentSignature: BufferSignature {
    var type: MetalTangent.Type = MetalTangent.self
    var count: Int
    var contents: [MetalTangent]
    var stride: Int = MemoryLayout<MetalTangent>.stride
    var index: Int
    var empty: Bool = false
    var mode: MTLResourceOptions
}

struct UIntSignature: BufferSignature {
    var type: uint.Type = uint.self
    var count: Int
    var contents: [uint]
    var stride: Int = MemoryLayout<uint>.stride
    var index: Int
    var empty: Bool = false
    var mode: MTLResourceOptions
}

struct FloatSignature: BufferSignature {
    var type: Float.Type = Float.self
    var count: Int
    var contents: [Float]
    var stride: Int = MemoryLayout<Float>.stride
    var index: Int
    var empty: Bool = false
    var mode: MTLResourceOptions
}

struct ArcSignature: BufferSignature {
    var type: MetalArc.Type = MetalArc.self
    var count: Int
    var contents: [MetalArc]
    var stride: Int = MemoryLayout<MetalArc>.stride
    var index: Int
    var empty: Bool = false
    var mode: MTLResourceOptions
}

//Utility delegate used to find collisions between player and environment
class CollisionHandler {
    //Supervisor
    private unowned let level: LevelView
    private let radius: CGFloat
    private unowned let metal: MetalDelegate
    
    //Initializes delegate with reference to supervisor
    init(level: LevelView, radius: CGFloat, metal: MetalDelegate) {
        self.level = level
        self.radius = radius
        self.metal = metal
        metal.buildPipeline(called: "collide")
    }
    
    //Find contacts along player path with environment lines
    func findContact(from position: Position, to point: Position) -> Position? {
        let start = (level.matrix * position).flatten()
        let end = (level.matrix * point).flatten()
        let player: MetalTangent = MetalTangent(
            origin: simd_float2(x: Float(start.x), y: Float(start.y)),
            outpost: simd_float2(x: Float(end.x), y: Float(end.y)),
            start: 0.0,
            end: 1.0
        )
        
        let arcs: [MetalArc] = level.arcs.map { $0.harden() }
        
        let signature = ShaderSignature(
            name: "collide",
            threads: arcs.count,
            inputs: [
                ArcSignature(
                    count: arcs.count,
                    contents: arcs,
                    index: 0,
                    mode: .cpuCacheModeWriteCombined
                ),
                TangentSignature(
                    count: 1,
                    contents: [player],
                    index: 1,
                    mode: .cpuCacheModeWriteCombined
                ),
                UIntSignature(
                    count: 1,
                    contents: [uint(arcs.count)],
                    index: 2,
                    mode: .cpuCacheModeWriteCombined
                ),
                FloatSignature(
                    count: 1,
                    contents: [Float(radius)],
                    index: 3,
                    mode: .cpuCacheModeWriteCombined
                )
            ],
            outputs: [
                "collisions" : FloatSignature(
                    count: arcs.count,
                    contents: [],
                    index: 4,
                    mode: .storageModeShared
                )
            ]
        )
        
        let results = metal.execute(signature)["collisions"]! as! [Float]
        let collision = results.filter { $0 >= 0 && $0 <= 1 }.min { $0 < $1 }
        if collision != nil {
            let d = end - start
            let c = CGFloat(collision!)
            return level.matrix.inverted() * Position(x: c * d.x + start.x, y: c * d.y + start.y, z: (level.matrix * position).z)
        }
        
        return nil
    }
}
