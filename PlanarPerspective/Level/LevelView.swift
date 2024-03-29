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

/*
 TODO:
 - Refactor and Centralize Line Compression, Graphics and Contact currently doing independently
 */

//The view for an individual level
class LevelView: UIView {
    
    //The delegates that deal with varius tasks
    var graphics: GraphicsHandler!
    var renderer: RenderHandler!
    var metal: MetalDelegate!
    var compression: CompressionHandler!
    var logic: LogicHandler!
    var input: InputHandler!
    var motion: MotionHandler!
    var contact: CollisionHandler!
    
    //Level contents
    var polygons: [Polygon]!
    var goal: Region!
    var position: Position!
    var region: Region!
    
    //State variables
    var state: State = .REST
    var matrix: MatrixTransform = MatrixTransform.identity
    var arcs: [Arc]!
    
    //Display link to update view with each frame
    var display: CADisplayLink?
    var framerate: CGFloat = 30.0
    var transit: Int = 15
    
    //Initialize from Level type
    init(frame: CGRect, level: Level) {
        super.init(frame: frame)
        
        //Initialize from level data
        polygons = level.polygons
        goal = level.goal
        position = level.position
        region = level.bounds
        
        //Initialize and assign delegates
        graphics = GraphicsHandler(level: self)
        renderer = RenderHandler()
        metal = try! MetalDelegate(level: self)
        logic = LogicHandler(level: self)
        input = InputHandler(level: self)
        motion = MotionHandler(level: self)
        contact = CollisionHandler(level: self, radius: 10, metal: metal)
        //contact = CollisionHandlerOld(level: self, radius: 10)
        compression = CompressionHandler(polygons: polygons, metal: metal)
        
        //Setup display link
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 / framerate) { self.loop() }
        //display = CADisplayLink(target: self, selector: #selector(loop))
        //display?.add(to: .current, forMode: .common)
        backgroundColor = .white
    }
    
    //Called before each frame to move the player (if applicable) and redraw the view
    @objc
    func loop() {
        let compute: DispatchGroup = DispatchGroup()
        DispatchQueue.main.async(group: compute) {
            self.logic.propogate()
            self.compress()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 / framerate) {
            compute.wait()
            self.motion.move()
            self.render()
            self.loop()
        }
    }
    
    //Called once the player reaches the goal to trigger success sequence and exit to menu
    //NOTE: In progress
    func arrived() {
        state = .ARRIVED
    }
    
    //Marks the view as needing refresh before frame render, calling draw(_:)
    func render() {
        setNeedsDisplay()
    }
    
    func compress() {
        arcs = compression.compress(transform: matrix)
    }
    
    //Calls the render delegate
    override func draw(_ rect: CGRect) {
        if arcs == nil {
            arcs = compression.compress(transform: matrix)
        }
        if let context = UIGraphicsGetCurrentContext() {
            let frame = graphics.build()
            input.update(frame.planeform)
            renderer!.render(items: frame.items, context: context)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
