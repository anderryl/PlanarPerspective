//
//  DrawItem.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 5/18/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit

enum DrawItem {
    case LINE(CGPoint, CGPoint, CGColor)
    case CIRCLE(CGPoint, CGFloat, CGColor)
    case RECTANGLE(CGPoint, CGSize, CGColor)
    case PATH(CGPath, CGColor)
}
