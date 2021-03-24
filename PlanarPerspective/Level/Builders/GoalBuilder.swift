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
    func build(from transform: Transform, state: Int) -> [DrawItem] {
        //Flatten the goal
        let flat = transform.method(Polygon(vertices: [level.goal.origin, level.goal.outpost]))
        let lines = flat.lines()
        
        //Find the goal endpoints
        let one = lines.first!.origin
        let two = lines.first!.outpost
        
        //Calculate the current opacity
        let alpha: CGFloat = 0.3 - 0.2 * sin(CGFloat(state) / 20)
        
        //Build and return a rectabgle from the endpoints in the current opacity of green
        return [.RECTANGLE(one, CGSize(width: two.x - one.x, height: two.y - one.y), .init(srgbRed: 0, green: 1, blue: 0, alpha: alpha), 1)]
    }
}
