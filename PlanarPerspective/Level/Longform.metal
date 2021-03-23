//
//  longform.metal
//  PlanarPerspective
//
//  Created by Rylie Anderson on 12/14/20.
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

static float2 intersection(MetalSegment first, MetalSegment second) {
    float delta1x = first.outpost.x - first.origin.x;
    float delta1y = first.outpost.y - first.origin.y;
    float delta2x = second.outpost.x - second.origin.x;
    float delta2y = second.outpost.y - second.origin.y;
    
    if (delta2x == 0 && delta2y == 0) {
        return {-1, -1};
    }

    //Create a 2D matrix from the vectors and calculate the determinant
    float determinant = delta1x * delta2y - delta2x * delta1y;
    
    //If it is zero or very close, the lines are parallel
    if (abs(determinant) < 0.0001) {
        return {-1, -1};
    }
    
    //If both coefficients are between 1 and 0, there is an intersection
    //The percentage of the length along the segment the intersection occurs
    float ab = ((first.origin.y - second.origin.y) * delta2x - (first.origin.x - second.origin.x) * delta2y) / determinant;
    float cd = ((first.origin.y - second.origin.y) * delta1x - (first.origin.x - second.origin.x) * delta1y) / determinant;
    return {ab, cd};
}
/*
//PolyOne approaches the juntion, and poly two escapes it
static bool junction(MetalSegment segment, MetalSegment polyOne, MetalSegment polyTwo) {
    
}
 */

static bool internal(MetalVertex vert, MetalPolygon polygon) {
    int inters = 0;
    MetalSegment test = MetalSegment{MetalVertex{-2371.21, -19235.57}, vert};
    for (int c = 0; c < polygon.count; c++) {
        MetalSegment cut;
        if (c == polygon.count - 1) {
            cut = MetalSegment{polygon.vertices[c], polygon.vertices[0]};
        }
        else {
            cut = MetalSegment{polygon.vertices[c], polygon.vertices[c + 1]};
        }
        float2 inter = intersection(test, cut);
        if (inter.x < 1) {
            if (inter.y >= 0 && inter.y <= 1) {
                inters++;
            }
        }
    }
    return (inters % 2) == 1;
}

static MetalEdge clipPolygon(MetalEdge initial, MetalPolygon polygon, device DebuggeringMetal *debug, uint index) {
    MetalEdge edge = MetalEdge{{}, 0};
    for (int s = 0; s < initial.count; s++) {
        MetalSegment segment = initial.segments[s];
        float dx = segment.outpost.x - segment.origin.x;
        float dy = segment.outpost.y - segment.origin.y;
        float dz = segment.outpost.z - segment.origin.z;
        array<float, 20> inters = {0};
        int intercount = 1;
        for (int c = 0; c < polygon.count; c++) {
            MetalSegment cut;
            if (c == polygon.count - 1) {
                cut = MetalSegment{polygon.vertices[c], polygon.vertices[0]};
            }
            else {
                cut = MetalSegment{polygon.vertices[c], polygon.vertices[c + 1]};
            }
            float2 inter = intersection(segment, cut);
            if (inter.x > 0 && inter.x < 1) {
                if (inter.y >= 0 && inter.y <= 1) {
                    //Normal Case
                    if (inter.x * dz + segment.origin.z < inter.y * (cut.outpost.z - cut.origin.z) + cut.origin.z) {
                        debug[index].status = max(debug[index].status, 1);
                        return initial;
                    }
                    inters[intercount++] = inter.x;
                    debug[index].intersections++;
                }
                /*if (inter.y == 1 || inter.y == 0) {
                    //On polygons endpoint
                    if (inter.x * dz + segment.origin.z < inter.y * (cut.outpost.z - cut.origin.z) + cut.origin.z) {
                        debug[index].status = max(debug[index].status, 1);
                        return initial;
                    }
                    inters[intercount++] = inter.x;
                    debug[index].intersections++;
                }*/
            }
        }
        inters[intercount++] = 1;
        if (intercount == 2) {
            bool breakout = false;
            if (internal(MetalVertex{(segment.origin.x + segment.outpost.x) / 2, (segment.origin.y + segment.outpost.y) / 2, (segment.origin.z + segment.outpost.z) / 2}, polygon)) {
                for (int c = 0; c < polygon.count; c++) {
                    MetalSegment cut;
                    if (c == polygon.count - 1) {
                        cut = MetalSegment{polygon.vertices[c], polygon.vertices[0]};
                    }
                    else {
                        cut = MetalSegment{polygon.vertices[c], polygon.vertices[c + 1]};
                    }
                    float2 inter = intersection(segment, cut);
                    if (inter.y >= 0 && inter.y <= 1) {
                        if (inter.y * (cut.outpost.z - cut.origin.z) + cut.origin.z < inter.x * dz + segment.origin.z) {
                            debug[index].status = max(debug[index].status, 4);
                            breakout = true;
                            break;
                        }
                        else {
                            debug[index].code = 69;
                            debug[index].status = max(debug[index].status, 1);
                            return initial;
                        }
                    }
                }
                if (!breakout) {
                    edge.segments[edge.count++] = segment;
                }
                continue;
            }
            edge.segments[edge.count++] = segment;
            continue;
        }
        else {
            for (int i = 0; i < intercount - 1; i++) {
                MetalVertex mid = MetalVertex{(inters[i + 1] + inters[i]) / 2 * dx + segment.origin.x, (inters[i + 1] + inters[i]) / 2 * dy + segment.origin.y, (inters[i + 1] + inters[i]) / 2 * dz + segment.origin.z};
                if (!internal(mid, polygon)) {
                    MetalVertex origin = MetalVertex{inters[i] * dx + segment.origin.x, inters[i] * dy + segment.origin.y, inters[i] * dz + segment.origin.z};
                    MetalVertex outpost = MetalVertex{inters[i + 1] * dx + segment.origin.x, inters[i + 1] * dy + segment.origin.y, inters[i + 1] * dz + segment.origin.z};
                    MetalSegment peice = MetalSegment{origin, outpost};
                    edge.segments[edge.count++] = peice;
                    debug[index].status = max(debug[index].status, 2);
                }
                else {
                    debug[index].status = max(debug[index].status, 3);
                }
            }
        }
    }
    return edge;
}

kernel void longform(device const MetalPolygon *clips [[ buffer(0) ]], device MetalEdge *lines [[ buffer(1) ]], device DebuggeringMetal *debug [[ buffer(2) ]], device const uint2 *bounds [[ buffer(3) ]], uint index [[thread_position_in_grid]]) {
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
        //Makes a reference to the current clipping
        MetalPolygon clip = clips[c];
        //The current iteration being created and modified
        //MetalEdge current = edge;
        //If the clipping is only a line, it isn't relevant
        if (clip.count == 2) {
            continue;
        }
        edge = clipPolygon(edge, clip, debug, index);
    }
    //Move the result into the buffer replacing the input. This is effectively the return.
    lines[index] = edge;
}

