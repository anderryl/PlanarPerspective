//
//  GoalBuilder.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 6/23/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit

//Builder for the goal
class GoalBuilder: Builder {
    //Supervisor
    unowned var level: LevelView
    
    //Initializes from supervisor reference
    required init(level: LevelView) {
        self.level = level
    }
    
    //Build the goal element given the transition
    func build(from transform: MatrixTransform, state: Int) -> [DrawItem] {
        //Flatten the goal
        let flat = level.goal.flatten(transform: transform)
        
        let path: CGMutablePath = CGMutablePath()
        
        path.addLines(between: flat.vertices.map { $0.flatten() })
        path.closeSubpath()
        
        return [DrawItem.PATH(path, .init(srgbRed: 0, green: 0, blue: 0, alpha: 0.3 + (0.1 * cos(Double(state) / 15))), 1)]
    }
}
