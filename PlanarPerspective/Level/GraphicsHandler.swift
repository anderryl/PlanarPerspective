//
//  GraphicsHandler.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 5/18/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import CoreGraphics

struct Invalid {
    let origin: CGPoint
    let outpost: CGPoint
    var intensity: Double
}

struct BuildSnapshot {
    var position: CGPoint
    var goal: [CGPoint]
    var queue: [CGPoint]
    var invalids: [Invalid]
    var test: CGPoint?
    var state: Int
}

//Delegate class for building the graphics elements
class GraphicsHandler {
    //Supervisor
    unowned var level: LevelView
    //Current compiler
    var compiler: Compiler
    //State value used for smooth transitions
    var state: Int = 0
    var invalids: [Invalid] = []
    
    //Initializes delegate with supervisor reference
    init(level: LevelView) {
        self.level = level
        //Begin with a static compiler using the current plane
        compiler = StaticCompiler(level: level)
    }
    
    func center() -> CGPoint {
        return compiler.getCenter()
    }
    
    //Begin visual win sequence
    func arrived() {
        compiler = ArrivedCompiler(supervisor: level, state: state)
    }
    
    //Registers an invalid with the static compiler
    func registerInvalid(at point: CGPoint) {
        if let stat = compiler as? StaticCompiler {
            stat.registerInvalid(at: point)
        }
    }
    
    func snapshot() -> BuildSnapshot {
        let queue: [CGPoint]
        switch level.state {
        case .MOTION(let q):
            queue = q.map { (level.matrix * $0).flatten() }
        default:
            queue = []
        }
        return BuildSnapshot(
            position: (level.matrix * level.position).flatten(),
            goal: level.goal.flatten(transform: level.matrix).vertices.map { $0.flatten() },
            queue: queue,
            invalids: invalids,
            test: level.input.getTest(),
            state: state
        )
    }
    
    func ageInvalids() {
        var next: [Invalid] = []
        for invalid in invalids {
            next.append(Invalid(origin: invalid.origin, outpost: invalid.outpost, intensity: invalid.intensity - 0.02))
        }
        invalids = next
    }
    
    //Retreives the visual elements from the current compiler
    func build() -> [DrawItem] {
        //Increment the state value
        state += 1
        
        ageInvalids()
        
        //Return the compiler results
        return compiler.compile(snapshot())
    }
}
