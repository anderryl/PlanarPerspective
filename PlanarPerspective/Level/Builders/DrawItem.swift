//
//  DrawItem.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 5/18/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit

//Represents a drawable item
enum DrawItem {
    case ARC(CGPoint, CGPoint, CGPoint, CGColor, CGFloat, Int)
    case CIRCLE(CGPoint, CGFloat, CGColor, Int)
    case RECTANGLE(CGPoint, CGSize, CGColor, Int)
    case PATH(CGPath, CGColor, Int)
}
