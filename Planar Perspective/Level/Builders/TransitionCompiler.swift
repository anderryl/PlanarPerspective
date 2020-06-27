//
//  TransitionCompilar.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 6/10/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit

class TransitionCompiler: Compiler {
    unowned var level: LevelView
    internal var initial: Plane
    internal var final: Plane
    internal var factory: TransformFactory
    internal var rotation: CGFloat
    internal var length: Int
    internal var frame: Int = 0
    internal var lines: LineBuilder
    internal var motion: MotionBuilder
    internal var player: PlayerBuilder
    internal var goal: GoalBuilder
    
    
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
    }
    
    func status() -> Bool {
        if frame >= length {
            return true
        }
        return false
    }
    
    func compile() -> [DrawItem] {
        frame += 1
        let prog = CGFloat(frame) / CGFloat(length)
        var items: [DrawItem] = []
        let transform: Transform = factory(prog)
        items.append(contentsOf: lines.build(from: transform))
        items.append(contentsOf: motion.build(from: transform))
        items.append(contentsOf: player.build(from: transform))
        items.append(contentsOf: goal.build(from: transform))
        
        var translated: [DrawItem] = []
        let rot: CGAffineTransform = CGAffineTransform(rotationAngle: prog * rotation)
        let location = player.location().applying(rot)
        
        let dx = level.frame.width / 2 - location.x
        let dy = level.frame.height / 2 - location.y
        let slide = CGAffineTransform(translationX: dx, y: dy)
        for item in items {
            switch item {
            case .CIRCLE(let center, let radius, let color):
                let position = center.applying(rot).applying(slide)
                translated.append(.CIRCLE(position, radius, color))
            case .RECTANGLE(let position, let size, let color):
                var edges: [CGPoint] = []
                let initial: [CGPoint] = [CGPoint(x: position.x, y: position.y), CGPoint(x: position.x, y: position.y + size.height), CGPoint(x: position.x + size.width, y: position.y + size.height), CGPoint(x: position.x + size.width, y: position.y), CGPoint(x: position.x, y: position.y)]
                for i in 0 ... 4 {
                    edges.append(initial[i].applying(rot).applying(slide))
                }
                let path = CGMutablePath()
                path.addLines(between: edges)
                translated.append(.PATH(path, color))
            case .LINE(let origin, let outpost, let color):
                translated.append(.LINE(origin.applying(rot).applying(slide), outpost.applying(rot).applying(slide), color))
            default:
                break
            }
        }
        return translated
    }
}
