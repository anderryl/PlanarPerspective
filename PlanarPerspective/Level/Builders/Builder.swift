//
//  Builder.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 5/18/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit

//Protocol for all builders
protocol Builder {
    var level: LevelView {get set}
    
    init(level: LevelView)
    
    func build(from: MatrixTransform, state: Int) -> [DrawItem]
}
