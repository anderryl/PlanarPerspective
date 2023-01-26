//
//  Transition.swift
//  PlanarPerspective
//
//  Created by Rylie Anderson on 1/25/23.
//  Copyright © 2023 Anderson, Todd W. All rights reserved.
//

import Foundation

class TransitionState: Hashable {
    static func == (lhs: TransitionState, rhs: TransitionState) -> Bool {
        return lhs.source == rhs.source && lhs.destination == rhs.destination && lhs.length == rhs.length
    }
    
    var source: MatrixTransform
    var destination: MatrixTransform
    var factory: MatrixTransformFactory
    var progress: Int
    var length: Int
    
    init(source: MatrixTransform, destination: MatrixTransform, factory: @escaping MatrixTransformFactory, progress: Int, length: Int) {
        self.source = source
        self.destination = destination
        self.factory = factory
        self.progress = progress
        self.length = length
    }
    
    //Hasher doesn't consider current progress only persistent information
    func hash(into hasher: inout Hasher) {
        hasher.combine(source.hash())
        hasher.combine(destination.hash())
        hasher.combine(length)
    }
    
    func incremented() -> TransitionState {
        return TransitionState(source: source, destination: destination, factory: factory, progress: progress + 1, length: length)
    }
    
    func progressed(to value: Int) -> TransitionState {
        return TransitionState(source: source, destination: destination, factory: factory, progress: value, length: length)
    }
}
