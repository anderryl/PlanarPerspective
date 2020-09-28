//
//  LevelView.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 5/18/\\20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit

/*
 IDEAS:
 - Accelerate pace of movement as more queue items are added. Visual Fast forward effect?
 */
class LevelView: UIView {
    var graphics: GraphicsHandler!
    var renderer: RenderHandler!
    var compression: CompressionHandler!
    var logic: LogicHandler!
    var input: InputHandler!
    var motion: MotionHandler!
    var contact: ContactHandler!
    var polygons: [Polygon]!
    var goal: Goal!
    var display: CADisplayLink?
    var state: State = .REST
    var plane: Plane = .FRONT
    var position: Position!
    
    init(frame: CGRect, level: Level) {
        super.init(frame: frame)
        var new = Level(polygons: polygons, goal: goal, position: position)
        let encoder = JSONEncoder()
        let data = try? encoder.encode(new)
        
        polygons = level.polygons
        goal = level.goal
        position = level.position
        graphics = GraphicsHandler(level: self)
        renderer = RenderHandler()
        compression = CompressionHandler(level: self)
        logic = LogicHandler(level: self)
        input = InputHandler(level: self)
        motion = MotionHandler(level: self)
        contact = ContactHandler(level: self, radius: 10)
        display = CADisplayLink(target: self, selector: #selector(loop))
        display?.add(to: .current, forMode: .common)
        input.setup()
        backgroundColor = .white
    }
    
    @objc
    func loop() {
        motion.move()
        render()
    }
    
    func render() {
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            let items = graphics.build()
            renderer!.render(items: items, context: context)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
