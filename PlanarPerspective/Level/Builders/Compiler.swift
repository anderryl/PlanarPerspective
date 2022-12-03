//
//  Compiler.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 6/5/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import CoreGraphics

//A compiler capable of compiling nessecary visual elements
protocol Compiler {
    init()
    
    func setScaler(_ nscaler: @escaping Scaler)
    
    func compile(_ snapshot: BuildSnapshot) -> Frame
}
