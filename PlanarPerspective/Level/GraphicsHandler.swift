//
//  GraphicsHandler.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 5/18/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import CoreGraphics

//Delegate class for building the graphics elements
class GraphicsHandler {
    //Supervisor
    unowned var level: LevelView
    //Current compiler
    var compiler: Compiler
    //State value used for smooth transitions
    var state: Int = 0
    
    //Initializes delegate with supervisor reference
    init(level: LevelView) {
        self.level = level
        //Begin with a static compiler using the current plane
        compiler = StaticCompiler(level: level, plane: level.plane)
    }
    
    //Switch to a transition compiler
    func transition(from initial: Plane, to final: Plane) {
        compiler = TransitionCompiler(level: level, initial: initial, final: final, length: 40)
    }
    
    func center() -> CGPoint {
        return compiler.getCenter()
    }
    
    //Begin visual win sequence
    func arrived() {
        
    }
    
    //Registers an invalid with the static compiler
    func registerInvalid(at point: CGPoint) {
        if let stat = compiler as? StaticCompiler {
            stat.registerInvalid(at: point)
        }
    }
    
    //Retreives the visual elements from the current compiler
    func build() -> [DrawItem] {
        //If transitioning, check TransitionCompiler status
        if compiler is TransitionCompiler {
            if (compiler as! TransitionCompiler).status() {
                //If done, switch to StaticCompiler, switch to rest state, and check win condition
                compiler = StaticCompiler(level: level, plane: level.plane)
                level.state = .REST
                level.logic.check()
            }
        }
        
        //Increment the state value
        state += 1
        
        //Return the compiler results
        return compiler.compile(state: state)
    }
}
