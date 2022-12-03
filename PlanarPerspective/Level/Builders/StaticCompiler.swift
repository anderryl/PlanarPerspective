//
//  StaticCompiler.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 6/5/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit

//Graphics Compiler for the REST and MOTION states
class StaticCompiler: Compiler {
    
    //Children builders for each level element
    internal var lines: LineBuilder
    internal var motion: MotionBuilder
    internal var player: PlayerBuilder
    internal var goal: GoalBuilder
    internal var scaler: Scaler
    
    //Initializes from supervisor reference
    required init() {
        lines = LineBuilder()
        player = PlayerBuilder()
        motion = MotionBuilder()
        goal = GoalBuilder()
        scaler = ScalerFactory.BOUNDED.build()
    }
    
    func setScaler(_ nscaler: @escaping Scaler) {
        scaler = nscaler
    }
    
    //Compile the results of each child builder
    func compile(_ snapshot: BuildSnapshot) -> Frame {
        //Compile results
        
        let scale = scaler(snapshot.bounds, snapshot.frame, snapshot.state)
        let scaleform = CGAffineTransform(scaleX: scale, y: scale)

        let scaledSnap = snapshot.applying(scaleform)

        let center = scaledSnap.bounds.restrain(position: scaledSnap.position, frame: snapshot.frame)
        
        
        //Find offset
        let dx = snapshot.frame.width / 2 - center.x
        let dy = snapshot.frame.height / 2 - center.y
        
        //Apply offset to compiled results
        var slideform = CGAffineTransform(translationX: dx, y: dy)
        //var translation = CGAffineTransform(translationX: dx, y: dy)
        
        var items: [DrawItem] = []
        items.append(contentsOf: lines.build(from: scaledSnap))
        items.append(contentsOf: motion.build(from: scaledSnap))
        items.append(contentsOf: player.build(from: scaledSnap))
        items.append(contentsOf: goal.build(from: scaledSnap))
        var translated: [DrawItem] = []
        
        for item in items {
            switch item {
            case .CIRCLE(let position, let radius, let color, let layer):
                translated.append(.CIRCLE(position.applying(slideform), radius, color, layer))
            case .RECTANGLE(let position, let size, let color, let layer):
                translated.append(.RECTANGLE(position.applying(slideform), size, color, layer))
            case .LINE(let origin, let outpost, let color, let thickness, let layer):
                translated.append(.LINE(origin.applying(slideform), outpost.applying(slideform), color, thickness, layer))
            case .PATH(let path, let color, let layer):
                translated.append(.PATH(path.copy(using: &slideform)!, color, layer))
            }
        }
        
        //Return offset results
        return Frame(items: translated, planeform: scaleform.concatenating(slideform).inverted())
    }
}
