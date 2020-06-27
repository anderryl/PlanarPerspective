//
//  ExpirimentalCompressionHandler.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 6/2/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit

/*
 Class designed to compress the 3-dimensional level into renderable 2-d lines
 */
class CompressionHandler {
    unowned var level: LevelView
    let polygons: [Polygon]
    
    init(level: LevelView) {
        self.level = level
        polygons = level.polygons
    }
    
    //Hashable Tuple stand-in
    struct Pairing: Hashable {
        var polygon: Polygon
        var vertex: Vertex
    }
    
    /*
     Compresses the 3-dimensional polygons into 2-dimensional lines
     Expensive process, so cache when possible
     */
    func compress(with transform: Transform, reverse: Bool) -> [Line] {
        //Polygons standardized to viewing plane
        var standards: [Polygon] = []
        
        //Cached depth functions for each polygon
        var planes: [Polygon : (_: CGPoint) -> CGFloat] = [:]
        
        //Building standards list and depth functions list
        for polygon in polygons {
            let standard = transform(polygon)
            standards.append(standard)
            planes[standard] = (try? planize(polygon: standard)) ?? { (_ point: CGPoint) in return 0.0 }
        }
        
        /*
         Labeles segments of a given line as under or over a specific polygon using midpoint testing
         */
        func cross(polygon: Polygon, with edge: Edge) -> [Line] {
            let line = edge.flatten()
            var intersections: [CGPoint] = []
            //Compile all intersection points
            for side in polygon.edges() {
                if let intersection = intersection(between: side.flatten(), and: line) {
                    intersections.append(intersection)
                    //If line has a lower z-value, return the full segment
                    if crawl(along: edge, to: intersection) < crawl(along: side, to: intersection) {
                        return [edge.flatten()]
                    }
                }
            }
            //If line does not cross the polygon's borders
            if intersections.count == 0 {
                let midcoordinate = midpoint(of: line.origin, and: line.outpost)
                //If the midpoint of the line is enclosed  by the polygon, the entire segment is; vice versa
                if encloses(point: midcoordinate, by: polygon) {
                    //If the plane has a lower z-value return no part; vice versa
                    if planes[polygon]!(midcoordinate) < crawl(along: edge, to: midcoordinate) {
                        return []
                    }
                    else {
                        return [line]
                    }
                }
                else {
                    return [line]
                }
            }
            //If there are intersections sort them by location
            intersections.sort { $0 | line.origin < $1 | line.origin }
            intersections.insert(line.origin, at: 0)
            intersections.append(line.outpost)
            var lines: [Line] = []
            //Test the midpoint of each section
            //If it is enclosed the entire line is and vice versa
            for i in 0 ..< intersections.count - 1 {
                let origin = intersections[i]
                let outpost = intersections[i + 1]
                let mid = midpoint(of: origin, and: outpost)
                if !encloses(point: mid, by: polygon) {
                    lines.append(Line(origin: origin, outpost: outpost))
                }
            }
            //Return compiled list
            return lines
        }
        
        //List of lines to be rendered
        var lines: [Line] = []
        
        for polygonOne in standards {
            EdgeScope: for edgeOne in polygonOne.edges() {
                //Stores the clipped line to be rendered
                var clippings: [Line] = [edgeOne.flatten()]
                
                //Iterate over all non-parent polygons
                for polygonTwo in standards {
                    if polygonOne == polygonTwo {
                        continue
                    }
                    //Add surviving segments to clippings
                    clippings.append(contentsOf: cross(polygon: polygonTwo, with: edgeOne))
                }
                //Find shared ground between surviving segment groups
                let set = shared(between: clippings, against: edgeOne.flatten(), groups: standards.count)
                lines.append(contentsOf: set)
            }
        }
        //Return the compiled list
        return lines
    }
    
    /*
     Determines whether a polygon encloses a particular point
     */
    func encloses(point: CGPoint, by polygon: Polygon) -> Bool {
        //Counts intersections
        var count: Int = 0
        //Arbitrary nonconformative point to dray line from
        let ray = Line(origin: CGPoint(x: -845.6, y: 353.7), outpost: point)
        //Determines enclosure status by the even-odd rule
        for line in polygon.lines() {
            if intersection(between: ray, and: line) != nil {
                count += 1
            }
        }
        if count % 2 == 1 {
            return true
        }
        return false
    }
    
    /*
     Finds shared space between multiple lines
     */
    func shared(between lines: [Line], against original: Line, groups: Int) -> [Line] {
        //Adds Start and End points on the line graph
        var ticks: [(point: CGPoint, type: Bool)] = []
        for line in lines {
            ticks.append((point: line.origin, type: true))
            ticks.append((point: line.outpost, type: false))
        }
        //NOTE: I hate closure shorthand; it is extremely unreadable
        //Sorts the points on the list
        ticks.sort { $0.point | original.origin < $1.point | original.origin }
        var running: Int = 0
        //Labels the graph by value for each region
        let graph: [Int] = ticks.map { (tick) -> Int in
            if tick.type {
                running += 1
                return running
            }
            else {
                running -= 1
                return running
            }
        }
        //Iterates over the graph to find high value regions, indicating all lines sharing the region
        //Utilizes slot-push form
        var beginning: CGPoint?
        var i = 0
        var ret: [Line] = []
        for tick in graph {
            //If value of ticks is equal to number of groups, set up region for addition
            if tick == groups {
                beginning = ticks[i].point
            }
            //If there is already a beginning value, add line and reset
            else if let origin = beginning {
                ret.append(Line(origin: origin, outpost: ticks[i].point))
                beginning = nil
            }
            i += 1
        }
        return ret
    }
    
    enum CompressionError: Error {
        case LINE
    }
    
    /*
     Finds the depth function for a polygon
    */
    func planize(polygon: Polygon) throws -> (_: CGPoint) -> CGFloat {
        if polygon.vertices.count == 2 {
            throw CompressionError.LINE
        }
        let v = polygon.vertices
        let px = (v[1].y - v[0].y) * (v[2].z - v[0].z) - (v[2].y - v[0].y) * (v[1].z - v[0].z)
        let py = (v[2].x - v[0].x) * (v[1].z - v[0].z) - (v[1].x - v[0].x) * (v[2].z - v[0].z)
        let pz = (v[1].x - v[0].x) * (v[2].y - v[0].y) - (v[2].x - v[0].x) * (v[1].y - v[0].y)
        let vert = polygon.vertices[0]
        let x0 = vert.x
        let y0 = vert.y
        let z0 = vert.z
        func evaluate(_ point: CGPoint) -> CGFloat {
            return ((-px * (point.x - x0) - py * (point.y - y0)) / pz) + z0
        }
        return evaluate
    }
    
    /*
     Finds the intersection between two lines
     */
    func intersection(between first: Line, and second: Line) -> CGPoint? {
        //Calculate the differences between the start and end X/Y positions for each of the points
        let delta1x = first.outpost.x - first.origin.x
        let delta1y = first.outpost.y - first.origin.y
        let delta2x = second.outpost.x - second.origin.x
        let delta2y = second.outpost.y - second.origin.y

        // create a 2D matrix from the vectors and calculate the determinant
        let determinant = delta1x * delta2y - delta2x * delta1y

        if abs(determinant) < 0.0001 {
            return nil
        }

        //If the coefficients are between 0 and 1, there is an intersection
        let ab = ((first.origin.y - second.origin.y) * delta2x - (first.origin.x - second.origin.x) * delta2y) / determinant
        if ab > 0 && ab < 1 {
            let cd = ((first.origin.y - second.origin.y) * delta1x - (first.origin.x - second.origin.x) * delta1y) / determinant
            if cd > 0 && cd < 1 {
                //Lines cross, so figure out where
                let intersectX = first.origin.x + ab * delta1x
                let intersectY = first.origin.y + ab * delta1y
                return CGPoint(x: intersectX, y: intersectY)
            }
        }
        
        //Lines don't cross
        return nil
    }
    
    /*
     Finds depth of a 2-dimensional point mapped on an edge
     */
    func crawl(along edge: Edge, to point: CGPoint) -> CGFloat {
        //NOTE: Could use the distance function, but, for this application, this method saves two sqrts
        let ratio = sqrt((pow(point.x - edge.origin.x, 2.0) + pow(point.y - edge.origin.y, 2.0)) / (pow(edge.outpost.x - edge.origin.x, 2.0) + pow(edge.outpost.y - edge.origin.y, 2.0)))
        
        return ratio * (edge.outpost.z - edge.origin.z) + edge.origin.z
    }
    
    /*
     Finds the midpoint between two points
     */
    func midpoint(of first: CGPoint, and second: CGPoint) -> CGPoint {
        let dx = second.x - first.x
        let dy = second.y - first.y
        return CGPoint(x: first.x + dx / 2, y: first.y + dy / 2)
    }
}
