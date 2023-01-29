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
    var type: UInt.Type = UInt.self
    var count: Int
    var contents: [UInt]
    var stride: Int = MemoryLayout<UInt>.stride
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

struct CollisionSignature: BufferSignature {
    var type: simd_float3.Type = simd_float3.self
    var count: Int
    var contents: [simd_float3]
    var stride: Int = MemoryLayout<simd_float3>.stride
    var index: Int
    var empty: Bool = true
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
        metal.buildPipeline(called: "collide", constant: radius, type: .float)
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
        for arc in arcs {
            print("origin: ", arc.c)
            print("outpost: ", arc.a + arc.b + arc.c)
            print("control: ", 0.25 * arc.a + 0.5 * arc.b + arc.c)
            print("\n\n")
        }
        
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
                    contents: [UInt(1)],
                    index: 2,
                    mode: .cpuCacheModeWriteCombined
                )
            ],
            outputs: [
                "collisions" : CollisionSignature(
                    count: arcs.count,
                    contents: [],
                    index: 3,
                    mode: .storageModeShared
                )
            ]
        )
        
        let results = (metal.execute(signature)["collisions"]! as! [simd_float3])
        let collision = results.filter { $0.z >= 0 }.min { $0.z < $1.z }
        
        if let actual = collision {
            return level.matrix.inverted() * Position(x: CGFloat(actual.x), y: CGFloat(actual.y), z: (level.matrix * position).z)
        }
        
        return nil
    }
}
