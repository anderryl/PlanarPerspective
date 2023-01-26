//
//  Edge.swift
//  PlanarPerspective
//
//  Created by Rylie Anderson on 11/25/22.
//  Copyright © 2022 Anderson, Todd W. All rights reserved.
//

import Foundation
import CoreGraphics

//Represents a three dimensional curve connecting two vertices, following a control vertex
struct Curve: Codable, Hashable {
    var origin: Vertex
    var outpost: Vertex
    var control: Vertex
    var thickness: CGFloat
    
    init(origin: Vertex, outpost: Vertex, thickness: CGFloat) {
        self.origin = origin
        self.outpost = outpost
        self.control = 0.5 * (origin + outpost)
        self.thickness = thickness
    }
    
    init(origin: Vertex, outpost: Vertex, control: Vertex, thickness: CGFloat) {
        self.origin = origin
        self.outpost = outpost
        self.control = control
        self.thickness = thickness
    }
    
    //Retreives the two dimensional line associated with this edge
    func flatten() -> Arc {
        return Arc(origin: origin.flatten(), outpost: outpost.flatten(), control: control.flatten(), thickness: thickness)
    }
    
    //Transforms each point of the curve
    func applying(_ transform: CGAffineTransform) -> Curve {
        return Curve(origin: origin.applying(transform), outpost: outpost.applying(transform), control: control.applying(transform), thickness: thickness)
    }
    
    func harden(_ p: Int) -> MetalEdge {
        return MetalEdge(segments: (MetalSegment(origin: origin.harden(), outpost: outpost.harden(), markline: MarkLine()), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment()), count: 1, polygon: UInt32(p))
    }
}
