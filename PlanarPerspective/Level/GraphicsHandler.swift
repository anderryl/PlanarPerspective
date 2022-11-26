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
    let origin: Position
    let outpost: Position
    var intensity: Double
}

struct CompressedInvalid {
    let origin: CGPoint
    let outpost: CGPoint
    let intensity: Double
}

struct Test {
    var point: CGPoint
    var valid: Bool
    var intersect: CGPoint?
}

struct BuildSnapshot {
    var position: CGPoint
    var bounds: Polygon
    var scale: CGFloat
    var lines: [Line]
    var goal: [CGPoint]
    var queue: [CGPoint]
    var invalids: [CompressedInvalid]
    var test: Test?
    var frame: CGRect
    var state: Int
    
    func applying(_ transform: CGAffineTransform) -> BuildSnapshot {
        return BuildSnapshot(
            position: position.applying(transform),
            bounds: bounds.applying(transform),
            //Some of the most heinous code ever written
            scale: (CGPoint(x: 0, y: 0).applying(transform) | CGPoint(x: 1, y: 1).applying(transform)) / sqrt(2.0),
            lines: lines.map { Line(origin: $0.origin.applying(transform), outpost: $0.outpost.applying(transform)) },
            goal: goal.map { $0.applying(transform) },
            queue: queue.map { $0.applying(transform) },
            invalids: invalids.map { CompressedInvalid(origin: $0.origin.applying(transform), outpost: $0.outpost.applying(transform), intensity: $0.intensity ) },
            test: test == nil ? nil : Test(point: test!.point.applying(transform), valid: test!.valid, intersect: test!.intersect?.applying(transform)),
            frame: frame,
            state: state
        )
    }
}

struct Frame {
    var items: [DrawItem]
    var planeform: CGAffineTransform
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
    
    //Begin visual win sequence
    func arrived() {
        compiler = ArrivedCompiler()
    }
    
    //Registers an invalid with the static compiler
    func registerInvalid(at point: Position) {
        switch level.state {
        case .MOTION(let queue):
            invalids.append(Invalid(origin: queue.last!, outpost: point, intensity: 1.0))
        default:
            invalids.append(Invalid(origin: level.position, outpost: point, intensity: 1.0))
        }
    }
    
    func snapshot() -> BuildSnapshot {
        let queue: [CGPoint]
        let queuethree: [Position]
        switch level.state {
        case .MOTION(let q):
            queue = q.map { (level.matrix * $0).flatten() }
            queuethree = q
        default:
            queue = []
            queuethree = []
        }
        let position = (level.matrix * level.position).flatten()
        var test: Test? = nil
        if let testpt = level.input.getTest() {
            let intersect = level.contact.findContact(from: queuethree.last ?? level.position, to: level.matrix.unfold(point: testpt, onto: level.position))
            test = Test(
                point: testpt,
                valid: intersect == nil,
                intersect: intersect == nil ? nil : (level.matrix * intersect!).flatten()
            )
        }
        
        let bounds = level.region.flatten(transform: level.matrix)
        
        return BuildSnapshot(
            position: position,
            bounds: bounds,
            scale: 1,
            lines: level.compression.compress(with: level.matrix),
            goal: level.goal.flatten(transform: level.matrix).vertices.map { $0.flatten() },
            queue: queue,
            invalids: invalids.map { CompressedInvalid(origin: (level.matrix * $0.origin).flatten(), outpost: (level.matrix * $0.outpost).flatten(), intensity: $0.intensity) },
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
    func build() -> Frame {
        update()
        
        //Return the compiler results
        return compiler.compile(snapshot())
    }
}
