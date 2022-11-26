//
//  Edge.swift
//  PlanarPerspective
//
//  Created by Rylie Anderson on 11/25/22.
//  Copyright © 2022 Anderson, Todd W. All rights reserved.
//

import Foundation
import CoreGraphics

//Represents a three dimensional edge connecting two vertices
struct Edge: Codable {
    var origin: Vertex
    var outpost: Vertex
    
    //Retreives the two dimensional line associated with this edge
    func flatten() -> Line {
        return Line(origin: origin.flatten(), outpost: outpost.flatten())
    }
    
    //Converts to a MetalEdge wrapper type
    func harden(id: Int) -> MetalEdge {
        return MetalEdge(segments: (MetalSegment(origin: origin.harden(), outpost: outpost.harden(), markline: MarkLine()), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment(), MetalSegment()), count: Int32(1), polygon: UInt32(id))
    }
}
