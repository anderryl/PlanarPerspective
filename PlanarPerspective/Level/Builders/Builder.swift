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
    func build(from: BuildSnapshot) -> [DrawItem]
}
