//
//  Compiler.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 6/5/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation

//A compiler capable of compiling nessecary visual elements
protocol Compiler {
    func compile(state: Int) -> [DrawItem]
}
