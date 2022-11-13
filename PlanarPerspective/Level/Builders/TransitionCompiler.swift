//
//  TransitionCompilar.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 6/10/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit

//Graphics Compiler for the TRANSITION state
class TransitionCompiler: Compiler {
    //Supervisor
    unowned var level: LevelView
    //The transition planes of the compiler
    internal var initial: Plane
    internal var final: Plane
    //Factory for this transition
    internal var factory: TransformFactory
    //Rotation value for this transition
    internal var rotation: CGFloat
    //Length of the transition (in frames)
    internal var length: Int
    //Current frame
    internal var frame: Int = 0
    //Children builders for each level element
    internal var lines: LineBuilder
    internal var motion: MotionBuilder
    internal var player: PlayerBuilder
    internal var goal: GoalBuilder
    internal var center: CGPoint
    
    //Initializes from supervisor reference and transition parameters
    init(level: LevelView, initial: Plane, final: Plane, length: Int) {
        self.level = level
        self.initial = initial
        self.final = final
        self.length = length
        let combo = ProjectionHandler.transformation(from: initial, to: final)
        factory = combo.factory
        rotation = combo.rotation
        lines = LineBuilder(level: level)
        player = PlayerBuilder(level: level)
        motion = MotionBuilder(level: level)
        goal = GoalBuilder(level: level)
        center = CGPoint(x: 0, y: 0)
    }
    
    //Current status of the transition
    func status() -> Bool {
        if frame >= length {
            return true
        }
        return false
    }
    
    func getCenter() -> CGPoint {
        return center
    }
    
    //Compiles results of children builders
    func compile(state: Int) -> [DrawItem] {
        //Increments frame
        frame += 1
        
        //Current progress as float between 0 and 1
        let prog = CGFloat(frame) / CGFloat(length)
        
        //Compiles items from builders
        var items: [DrawItem] = []
        let transform: Transform = factory(prog)
        items.append(contentsOf: lines.build(from: transform, state: state))
        items.append(contentsOf: motion.build(from: transform, state: state))
        items.append(contentsOf: player.build(from: transform, state: state))
        items.append(contentsOf: goal.build(from: transform, state: state))
        
        //Calculates translation
        var translated: [DrawItem] = []
        var rot: CGAffineTransform = CGAffineTransform(rotationAngle: prog * rotation)
        let restrained = level.region.restrain(position: transform.method(Polygon(vertices: [level.position])).vertices[0].flatten().applying(rot), transform: transform, frame: level.frame, rotation: rot)
        center = restrained
        let dx = level.frame.width / 2 - restrained.x
        let dy = level.frame.height / 2 - restrained.y
        var slide = CGAffineTransform(translationX: dx, y: dy)
        
        //Applies translation to each item
        for item in items {
            switch item {
            case .CIRCLE(let center, let radius, let color, let layer):
                let position = center.applying(rot).applying(slide)
                translated.append(.CIRCLE(position, radius, color, layer))
            case .RECTANGLE(let position, let size, let color, let layer):
                var edges: [CGPoint] = []
                let initial: [CGPoint] = [CGPoint(x: position.x, y: position.y), CGPoint(x: position.x, y: position.y + size.height), CGPoint(x: position.x + size.width, y: position.y + size.height), CGPoint(x: position.x + size.width, y: position.y), CGPoint(x: position.x, y: position.y)]
                for i in 0 ... 4 {
                    edges.append(initial[i].applying(rot).applying(slide))
                }
                let path = CGMutablePath()
                path.addLines(between: edges)
                translated.append(.PATH(path, color, layer))
            case .LINE(let origin, let outpost, let color, let layer):
                translated.append(.LINE(origin.applying(rot).applying(slide), outpost.applying(rot).applying(slide), color, layer))
            case .PATH(let path, let color, let layer):
                translated.append(.PATH(path.copy(using: &rot)!.copy(using: &slide)!, color, layer))
            default:
                break
            }
        }
        
        //Returns translated items
        return translated
    }
}
