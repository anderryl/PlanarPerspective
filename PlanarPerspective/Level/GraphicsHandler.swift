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

struct Test {
    var point: CGPoint
    var valid: Bool
    var intersect: CGPoint?
}

struct BuildSnapshot {
    var position: CGPoint
    var center: CGPoint
    var lines: [Line]
    var goal: [CGPoint]
    var queue: [CGPoint]
    var invalids: [Invalid]
    var test: Test?
    var frame: CGRect
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
        compiler = StaticCompiler()
    }
    
    func center() -> CGPoint {
        return level.region.flatten(transform: level.matrix).restrain(position: (level.matrix * level.position).flatten(), frame: level.frame)
    }
    
    //Begin visual win sequence
    func arrived() {
        compiler = ArrivedCompiler()
    }
    
    //Registers an invalid with the static compiler
    func registerInvalid(at point: CGPoint) {
        switch level.state {
        case .MOTION(let queue):
            invalids.append(Invalid(origin: (level.matrix * queue.last!).flatten(), outpost: point, intensity: 1.0))
        default:
            invalids.append(Invalid(origin: (level.matrix * level.position).flatten(), outpost: point, intensity: 1.0))
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
        let position = (level.matrix * level.position).flatten()
        var test: Test? = nil
        if let testpt = level.input.getTest() {
            let intersect = level.contact.findContact(from: queue.last ?? position, to: testpt)
            test = Test(
                point: testpt,
                valid: intersect == nil,
                intersect: intersect
            )
        }
        
        return BuildSnapshot(
            position: position,
            center: center(),
            lines: level.compression.compress(with: level.matrix),
            goal: level.goal.flatten(transform: level.matrix).vertices.map { $0.flatten() },
            queue: queue,
            invalids: invalids,
            test: test,
            frame: level.frame,
            state: state
        )
    }
    
    func update() {
        var next: [Invalid] = []
        for invalid in invalids {
            next.append(Invalid(origin: invalid.origin, outpost: invalid.outpost, intensity: invalid.intensity - 0.02))
        }
        invalids = next
        state += 1
    }
    
    //Retreives the visual elements from the current compiler
    func build() -> [DrawItem] {
        
        update()
        
        //Return the compiler results
        return compiler.compile(snapshot())
    }
}
