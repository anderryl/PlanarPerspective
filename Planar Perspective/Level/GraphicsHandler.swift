//
//  GraphicsHandler.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 5/18/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation

class GraphicsHandler {
    unowned var level: LevelView
    var compiler: Compiler
    
    init(level: LevelView) {
        self.level = level
        compiler = StaticCompiler(level: level, plane: .FRONT)
        //compiler = TransitionCompiler(level: level, initial: .RIGHT(0), final: .FRONT(0), length: 60)
    }
    
    func transition(from initial: Plane, to final: Plane) {
        compiler = TransitionCompiler(level: level, initial: initial, final: final, length: 60)
    }
    
    func build() -> [DrawItem] {
        if compiler is TransitionCompiler {
            if (compiler as! TransitionCompiler).status() {
                compiler = StaticCompiler(level: level, plane: level.plane)
                level.state = .REST
            }
        }
        return compiler.compile()
    }
}
