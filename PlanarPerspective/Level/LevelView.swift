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

//The view for an individual level
class LevelView: UIView {
    
    //The delegates that deal with varius tasks
    var graphics: GraphicsHandler!
    var renderer: RenderHandler!
    var compression: CompressionHandler!
    var logic: LogicHandler!
    var input: InputHandler!
    var motion: MotionHandler!
    var contact: ContactHandler!
    
    //Level contents
    var polygons: [Polygon]!
    var goal: Goal!
    var position: Position!
    
    //State variables
    var state: State = .REST
    var plane: Plane = .FRONT
    
    //Display link to update view with each frame
    var display: CADisplayLink?
    
    //Initialize from Level type
    init(frame: CGRect, level: Level) {
        super.init(frame: frame)
        
        //Initialize from level data
        polygons = level.polygons
        goal = level.goal
        position = level.position
        
        //Initialize and assign delegates
        graphics = GraphicsHandler(level: self)
        renderer = RenderHandler()
        compression = try! CompressionHandler(level: self)
        logic = LogicHandler(level: self)
        input = InputHandler(level: self)
        motion = MotionHandler(level: self)
        contact = ContactHandler(level: self, radius: 10)
        
        //Setup display link
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.025) {
            self.loop()
        }
        //display = CADisplayLink(target: self, selector: #selector(loop))
        //display?.add(to: .current, forMode: .common)
        backgroundColor = .white
    }
    
    //Called before each frame to move the player (if applicable) and redraw the view
    @objc
    func loop() {
        motion.move()
        render()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.025) {
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
    
    //Calls the render delegate
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
