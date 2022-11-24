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
    
    //Build the goal element given the transition
    func build(from snapshot: BuildSnapshot) -> [DrawItem] {
        
        let path: CGMutablePath = CGMutablePath()
        
        path.addLines(between: snapshot.goal)
        path.closeSubpath()
        
        return [DrawItem.PATH(path, .init(srgbRed: 0, green: 0, blue: 0, alpha: 0.3 + (0.1 * cos(Double(snapshot.state) / 15))), 1)]
    }
}
