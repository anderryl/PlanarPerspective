//
//  State.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 6/10/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit

enum State {
    case TRANSITION(Plane, Plane)
    case MOTION([CGPoint])
    case REST
}
