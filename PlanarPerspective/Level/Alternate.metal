//
//  Alternate.metal
//  PlanarPerspective
//
//  Created by Rylie Anderson on 11/15/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

#include <metal_stdlib>
#import "ShaderTypes.h"

using namespace metal;

/*
 This function is written in Metal Shading Language, which is, in effect, a very limited version of C++.
 This function is written to be executed in parallel on the GPU, one execution for each edge.
 
 Classes:
 MetalVertex: A ObjectiveC / MSL wrapper for my swift Vertex class.
    - Holds three float coordinates: x, y, and z.
 MetalPolygon: A wrapper for my swift Polygon class.
    - Contains an array of MetalVertex's.
 MetalSegment: A wrapper for my swift Edge class.
    - Contains two MetalVertex's: an origin and and outpost.
 MetalEdge: A wrapper for an array of my MetalSegments.
    - Begins as an array of the single original segment that will be divided up to populate the array.
 DebuggeringMetal: A container type for passing debugging information out of the function.
 
 Notes:
 -The way the rest of the game is set up, lower z values are closer to the camera and thus higher priority
    
 Arguments:
 - Clips: the MetalPolygon areas to clip out of the lines.
 - Lines: the Lines to be clipped and returned.
 - Debug: a tool I use to get information beyond the simple results of the function.
    - This is nessecary because these functions don't support breakpoints or internal tests, and all debugging must be based on inferences about the results spit out by the function.
 - Bounds: the total number of lines and clips to be iterated over.
    - This is nessecary to prevent the function from going over index bounds if grid size doesn't exactly match the number of elements of both types.
 */

kernel void longclip(device const MetalPolygon *clips [[ buffer(0) ]], device MetalEdge *lines [[ buffer(1) ]], device DebuggeringMetal *debug [[ buffer(2) ]], device const uint2 *bounds [[ buffer(3) ]], uint index [[thread_position_in_grid]]) {
    //If the index is out of bounds, stop before continuing and causing an error
    if (index >= bounds[0].y) {
        return;
    }
    //The previous iteration for reference
    MetalEdge edge = lines[index];
    //return;
    //Loops through all polygons to be clipped out of the lines
    for (uint c = 0; c < bounds[0].x; c++) {
        //The bool to break out of the clip loop if this polygon is deemed irrelevant
        bool breakout = false;
        //Code 1 indicates that line was tested
        debug[index].code = max(debug[index].code, 1);
        //Makes a reference to the current clipping
        MetalPolygon clip = clips[c];
        //The current iteration being created and modified
        MetalEdge current = MetalEdge{{}, 0};
        //If the clipping is only a line, it isn't relevant
        if (clip.count == 2) {
            continue;
        }
        //Bounding box to determine whether polygon is relevant to this clipping
        //Find the minimum and maximum x and y values of each
        //There is probably a much more efficient way to do this, but no array functions such as .min() and .max() are available here
        
        float minx = 100000;
        float maxx = -100000;
        float miny = 100000;
        float maxy = -100000;
        for (int i = 0; i < clip.count; i++) {
            MetalVertex p = clip.vertices[i];
            if (p.x > maxx) {
                maxx = p.x;
            }
            if (p.x < minx) {
                minx = p.x;
            }
            if (p.y > maxy) {
                maxy = p.y;
            }
            if (p.y < miny) {
                miny = p.y;
            }
        }
        float sminx = 100000;
        float smaxx = -100000;
        float sminy = 100000;
        float smaxy = -100000;
        for (int i = 0; i < 2; i++) {
            MetalVertex p;
            if (i == 0) {
                p = edge.segments[0].origin;
            }
            else {
                p = edge.segments[edge.count - 1].outpost;
            }
            if (p.x > smaxx) {
                smaxx = p.x;
            }
            if (p.x < sminx) {
                sminx = p.x;
            }
            if (p.y > smaxy) {
                smaxy = p.y;
            }
            if (p.y < sminy) {
                sminy = p.y;
            }
        }
        
        //If bounding boxes overlap, the clipping is irrelevant
        if (!((smaxx < maxx && smaxx > minx) || (sminx < maxx && sminx > minx))) {
            if (!((smaxy < maxy && smaxy > miny) || (sminy < maxy && sminy > miny))) {
                if (!((maxx < smaxx && maxx > sminx) || (minx < smaxx && minx > sminx))) {
                    if (!((maxy < smaxy && maxy > sminy) || (miny < smaxy && miny > sminy))) {
                        continue;
                    }
                }
            }
        }
        
        //Iterate through every segment of the edge
        for (int sub = 0; sub < edge.count; sub++) {
            //Code 2 there is a segment to be considered
            debug[index].code = max(debug[index].code, 2);
            //Allocate twenty element array of floats to store the alpha values (percentage of segment length past origin) of each intersection
            array<float, 20> intersections = {0};
            //The count of intersections
            int intercount = 1;
            //Reference to the current segment
            MetalSegment segment = edge.segments[sub];
            //Allocate a twenty element array of segments to store the lines of the clipping to check against
            array<MetalSegment, 20 > list = {};
            //Populate the list with each of the clipping's edges by forming a segment from every pair of consecutive vertices
            for (int i = 0; i < clip.count - 1; i++) {
                list[i] = MetalSegment{clip.vertices[i], clip.vertices[i + 1]};
            }
            //Add the final edge between the first and last vertices
            list[clip.count - 1] = MetalSegment{clip.vertices[clip.count - 1], clip.vertices[0]};
            //The winding number for an even-odd polygon interior check
            int winding = 0;
            //The vector components of the current segment
            float dx = segment.outpost.x - segment.origin.x;
            float dy = segment.outpost.y - segment.origin.y;
            float dz = segment.outpost.z - segment.origin.z;
            //If it is a point, move on
            if (dx == 0 && dy == 0) {
                continue;
            }
            
            //Iterate through the entire list and check the segment against each of the clipping's edges
            for (int i = 0; i < clip.count; i++) {
                //Reference to the current edge
                MetalSegment clipline = list[i];
                //The vector components of the current clipping edge
                float delta2x = clipline.outpost.x - clipline.origin.x;
                float delta2y = clipline.outpost.y - clipline.origin.y;
                
                if (delta2x == 0 && delta2y == 0) {
                    continue;
                }
     
                //Create a 2D matrix from the vectors and calculate the determinant
                float determinant = dx * delta2y - delta2x * dy;
                
                //If it is zero or very close, the lines are parallel
                if (abs(determinant) < 0.0001) {
                    continue;
                }
                
                //Code 3 if a comparison is applicable
                debug[index].code = max(debug[index].code, 3);
                //If both coefficients are between 1 and 0, there is an intersection
                //The percentage of the length along the segment the intersection occurs
                float ab = ((segment.origin.y - clipline.origin.y) * delta2x - (segment.origin.x - clipline.origin.x) * delta2y) / determinant;
                if (ab >= 0 && ab <= 1) {
                    //The percentage of the length along the clipping edge the intersection occurs
                    float cd = ((segment.origin.y - clipline.origin.y) * dx - (segment.origin.x - clipline.origin.x) * dy) / determinant;
                    if (cd >= 0 && cd <= 1) {
                        //Increment the debug object's intersection count
                        debug[index].intersections++;
                        //Add the intersection's alpha value and increment the intersection count
                        intersections[intercount++] = ab;
                        //The z value of the segment at the intersection point
                        float sz = ab * dz + segment.origin.z;
                        //The alpha value of the clipping edge at the intersection point
                        float cz = cd * (clipline.outpost.z - clipline.origin.z) + clipline.origin.z;
                        //If the segment's z value is lower than the clipping edge's, the clipping isn't relevant
                        if (sz < cz) {
                            //Exit Status 2 means it is above a clipping in the z priority
                            debug[index].status = max(debug[index].status, 2);
                            breakout = true;
                            break;
                        }
                        //If there is an intersection, increment the winding number
                        winding++;
                    }
                }
                //If the intersection occurs forward of the origin, check the clipping
                else if (ab >= 0) {
                    float cd = ((segment.origin.y - clipline.origin.y) * dx - (segment.origin.x - clipline.origin.x) * dy) / determinant;
                    //If the intersection occurs between the origin and the outpost of the clipping, increment the winding number
                    if (cd >= 0 && cd <= 1) {
                      winding++;
                    }
                }
            }
            //Continue the breakout sequence
            if (breakout) {
                break;
            }
            
            //Add the final point as the segments's endpoint
            intersections[intercount++] = 1.0;
            
            //Bubble sort for the win. Its a short list. I'm allowed to do this. I swear.
            //Sort the intersection points in ascending order
            for (int step = 0; step < intercount - 1; step++) {
              bool swapped = false;
              for (int i = 0; i < intercount - step - 1; ++i) {
                if (intersections[i] > intersections[i + 1]) {
                  float temp = intersections[i];
                  intersections[i] = intersections[i + 1];
                  intersections[i + 1] = temp;
                  swapped = true;
                }
              }
              if (!swapped) {
                break;
              }
            }
            
            winding = 0;
            
            MetalVertex one = MetalVertex{(intersections[0] + intersections[1]) / 2 * dx + segment.origin.x, (intersections[0] + intersections[1]) / 2 * dy + segment.origin.y, 0};
            
            MetalSegment test = MetalSegment{one, MetalVertex{123487.2, 586346.18, 0}};
            
            //Iterate through the entire list and check the segment against each of the clipping's edges
            for (int i = 0; i < clip.count; i++) {
                //Reference to the current edge
                MetalSegment clipline = list[i];
                //The vector components of the current clipping edge
                float delta1x = test.outpost.x - test.origin.x;
                float delta1y = test.outpost.y - test.origin.y;
                float delta2x = clipline.outpost.x - clipline.origin.x;
                float delta2y = clipline.outpost.y - clipline.origin.y;
                
                if (delta2x == 0 && delta2y == 0) {
                    continue;
                }
     
                //Create a 2D matrix from the vectors and calculate the determinant
                float determinant = delta1x * delta2y - delta2x * delta1y;
                
                //If it is zero or very close, the lines are parallel
                if (abs(determinant) < 0.0001) {
                    continue;
                }
                //If both coefficients are between 1 and 0, there is an intersection
                //The percentage of the length along the segment the intersection occurs
                float ab = ((test.origin.y - clipline.origin.y) * delta2x - (test.origin.x - clipline.origin.x) * delta2y) / determinant;
                float cd = ((test.origin.y - clipline.origin.y) * delta1x - (test.origin.x - clipline.origin.x) * delta1y) / determinant;
                if (cd > 0 && cd < 1 && ab > 0) {
                    winding++;
                }
            }
            
            //If the winding number is even, the point lies outside the clipping polygon
            bool outside = (winding % 2 == 0);
            
            //If there weren't any intersections (intercount of 2 including the beginning and endpoints) and the segment's origin is inside the clipping polygon, calculate the polygon's plane and evaluate
            if (intercount == 2 && !outside && clip.count > 2) {
                //Calculate the plane coefficients
                float a1 = clip.vertices[1].x - clip.vertices[0].x;
                float b1 = clip.vertices[1].y - clip.vertices[0].y;
                float c1 = clip.vertices[1].y - clip.vertices[0].z;
                float a2 = clip.vertices[2].x - clip.vertices[0].x;
                float b2 = clip.vertices[2].y - clip.vertices[0].y;
                float c2 = clip.vertices[2].z - clip.vertices[0].z;;
                float a = b1 * c2 - b2 * c1;
                float b = a2 * c1 - a1 * c2;
                float c = a1 * b2 - b1 * a2;
                float d = (-a * clip.vertices[0].x - b * clip.vertices[0].y - c * clip.vertices[0].z);
                //z = (ax + by + d) / -c
                //If the plane has a lower z-value at the segment's origin than the origin itself, obscure the entire segment
                float z = (a * segment.origin.x + b * segment.origin.y + d) / -c;
                if (z < segment.origin.z) {
                    //Exit Status 3 indicates the segment is obscured
                    debug[index].status = max(debug[index].status, 3);
                    //Continue without adding the segment
                    continue;
                }
                //Otherwise, break out to the next clipping (invalidating this entire run)
                breakout = true;
                break;
            }
            
            //Loop through intersections and build a segment from each consecutive pair
            for (int i = 0; i < intercount - 1; i++) {
                //If current segment is outside the polygon, add it
                //Build the origin and outpost using the alpha value, the origin, and the vector components
                MetalVertex origin = MetalVertex{intersections[i] * dx + segment.origin.x, intersections[i] * dy + segment.origin.y, intersections[i] * dz + segment.origin.z};
                MetalVertex outpost = MetalVertex{intersections[i + 1] * dx + segment.origin.x, intersections[i + 1] * dy + segment.origin.y, intersections[i + 1] * dz + segment.origin.z};
                
                winding = 0;
                
                MetalVertex one = MetalVertex{(intersections[i] + intersections[i + 1]) / 2 * dx + segment.origin.x, (intersections[i] + intersections[i + 1]) / 2 * dy + segment.origin.y, 0};
                
                MetalSegment test = MetalSegment{one, MetalVertex{123487.2, 586346.18, 0}};
                
                //Iterate through the entire list and check the segment against each of the clipping's edges
                for (int i = 0; i < clip.count; i++) {
                    //Reference to the current edge
                    MetalSegment clipline = list[i];
                    //The vector components of the current clipping edge
                    float delta1x = test.outpost.x - test.origin.x;
                    float delta1y = test.outpost.y - test.origin.y;
                    float delta2x = clipline.outpost.x - clipline.origin.x;
                    float delta2y = clipline.outpost.y - clipline.origin.y;
                    
                    if (delta2x == 0 && delta2y == 0) {
                        continue;
                    }
         
                    //Create a 2D matrix from the vectors and calculate the determinant
                    float determinant = delta1x * delta2y - delta2x * delta1y;
                    
                    //If it is zero or very close, the lines are parallel
                    if (abs(determinant) < 0.0001) {
                        continue;
                    }
                    //If both coefficients are between 1 and 0, there is an intersection
                    //The percentage of the length along the segment the intersection occurs
                    float ab = ((test.origin.y - clipline.origin.y) * delta2x - (test.origin.x - clipline.origin.x) * delta2y) / determinant;
                    float cd = ((test.origin.y - clipline.origin.y) * delta1x - (test.origin.x - clipline.origin.x) * delta1y) / determinant;
                    if (cd >= 0 && cd <= 1 && ab >= 0) {
                        winding++;
                    }
                }
                
                outside = (winding % 2) == 0;
                
                if (outside) {
                    
                    //Add the new segment to the current iteration and increment the count
                    current.segments[current.count++] = MetalSegment{origin, outpost};
                    //Misc currently points to the number of segments in each edge
                    debug[index].misc = current.count;
                }
                //Otherwise log debug information and move on
                else {
                    //Cuts signify the number of segments dropped
                    debug[index].cuts++;
                }
                //Toggle the inside/outside boolean
                outside = !outside;
            }
        }
        //Continue the breakout sequence
        if (breakout) {
            continue;
        }
        //Exit Status 1 indicates that the edge moved through the normal path
        debug[index].status = max(debug[index].status, 1);
        //Transfer the current iteration to the past one
        edge = current;
    }
    //Move the result into the buffer replacing the input. This is effectively the return.
    lines[index] = edge;
}
