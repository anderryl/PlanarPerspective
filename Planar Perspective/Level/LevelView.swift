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
    var polygons: [Polygon] = [Polygon(vertices: [Vertex(x: 90, y: 115, z: 77), Vertex(x: 100, y: 135, z: 77), Vertex(x: 100, y: 70, z: 77), Vertex(x: 80, y: 80, z: 77)]), Polygon(vertices: [Vertex(x: 70, y: 125, z: 87), Vertex(x: 90, y: 145, z: 87), Vertex(x: 125, y: 70, z: 87), Vertex(x: 60, y: 80, z: 87)])]
    var goal: Goal = Goal(origin: Vertex(x: 500, y: 550, z: 600), outpost: Vertex(x: 450, y: 400, z: 350))
    var display: CADisplayLink?
    var state: State = .REST
    var plane: Plane = .FRONT
    var position: Position = Position(x: 200, y: 200, z: 200)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
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
    /*
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive press: UIPress) -> Bool {
        return true
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    */
}
