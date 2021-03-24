//
//  ISwearItBetterWorkThisTime.metal
//  PlanarPerspective
//
//  Created by Rylie Anderson on 12/24/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

#include <metal_stdlib>
#import "ShaderTypes.h"
using namespace metal;

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
    if (abs(determinant) < 0.01) {
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

static bool internal(MetalVertex vert, MetalPolygon polygon, device DebuggeringMetal *debug, int index) {
    int inters = 0;
    MetalSegment test = MetalSegment{MetalVertex{-2371.21, -19235.57}, vert};
    debug[index].point = 2.11;
    for (int c = 0; c < polygon.count; c++) {
        MetalSegment cut;
        if (c == polygon.count - 1) {
            debug[index].point = 2.12;
            cut = MetalSegment{polygon.vertices[c], polygon.vertices[0]};
        }
        else {
            debug[index].point = 2.13;
            cut = MetalSegment{polygon.vertices[c], polygon.vertices[c + 1]};
        }
        debug[index].point = 2.14;
        float2 inter = intersection(test, cut);
        debug[index].point = 2.15;
        if (inter.x < 1) {
            if (inter.y > 0 && inter.y < 1) {
                inters++;
            }
        }
        if (inter.x == 1) {
            return false;
        }
    }
    debug[index].point = 2.16;
    return (inters % 2) == 1;
}

static bool above(MetalVertex vert, MetalPolygon polygon) {
    float a1 = polygon.vertices[1].x - polygon.vertices[0].x;
    float b1 = polygon.vertices[1].y - polygon.vertices[0].y;
    float c1 = polygon.vertices[1].z - polygon.vertices[0].z;
    float a2 = polygon.vertices[2].x - polygon.vertices[0].x;
    float b2 = polygon.vertices[2].y - polygon.vertices[0].y;
    float c2 = polygon.vertices[2].z - polygon.vertices[0].z;
    float a = b1 * c2 - b2 * c1;
    float b = a2 * c1 - a1 * c2;
    float c = a1 * b2 - b1 * a2;
    float d = (- a * polygon.vertices[0].x - b * polygon.vertices[0].y - c * polygon.vertices[0].z);
    float z = (a * vert.x + b * vert.y + d) / -c;
    return vert.z <= z;
}

static MetalEdge trim(MetalSegment segment, MetalPolygon polygon, device DebuggeringMetal *debug, int index) {
    if (polygon.count == 2) {
        return MetalEdge{{segment}, 1};
    }
    debug[index].point = 1.0;
    array<float, 40> inters = {0, 1};
    int intercount = 2;
    for (int i = 0; i < polygon.count; i++) {
        MetalSegment line;
        if (i == 0) {
            line = MetalSegment{polygon.vertices[polygon.count - 1], polygon.vertices[0]};
        }
        else {
            line = MetalSegment{polygon.vertices[i - 1], polygon.vertices[i]};
        }
        debug[index].point = 1.1;
        float2 intersect = intersection(segment, line);
        if (intersect.x < 1 && intersect.x > 0) {
            if (intersect.y <= 1 && intersect.y >= 0) {
                float linez = intersect.y * (line.outpost.z - line.origin.z) + line.origin.z;
                float segz = intersect.x * (segment.outpost.z - segment.origin.z) + segment.origin.z;
                debug[index].point = 1.2;
                if (segz <= linez) {
                    debug[index].status = max(debug[index].status, 1);
                    return MetalEdge{{segment}, 1};
                }
                debug[index].point = 1.3;
                debug[index].intersections++;
                inters[intercount++] = intersect.x;
            }
        }
        debug[index].point = 1.4;
    }
    debug[index].point = 2;
    //Confirmed
    if (intercount == 2) {
        MetalVertex mid = MetalVertex{(segment.origin.x + segment.outpost.x) / 2, (segment.origin.y + segment.outpost.y) / 2, (segment.origin.z + segment.outpost.z) / 2};
        debug[index].point = 2.1;
        if (internal(mid, polygon, debug, index)) {
            debug[index].point = 2.2;
            if (above(mid, polygon)) {
                debug[index].status = max(debug[index].status, 1);
                return MetalEdge{{segment}, 1};
            }
            else {
                debug[index].status = max(debug[index].status, 3);
                return MetalEdge{{}, 0};
            }
        }
        debug[index].point = 2.3;
        return MetalEdge{{segment}, 1};
    }
    debug[index].point = 3.0;
    //Confirmed
    for (int dsm = 0; dsm < intercount - 1; dsm++) {
        for (int i = 0; i < intercount - 1; i++) {
            if (inters[i] > inters[i + 1]) {
                float temp = inters[i];
                inters[i] = inters[i + 1];
                inters[i + 1] = temp;
            }
        }
    }
    
    debug[index].point = 4.0;
    MetalEdge ret = MetalEdge{{}, 0};
    float dx = segment.outpost.x - segment.origin.x;
    float dy = segment.outpost.y - segment.origin.y;
    float dz = segment.outpost.z - segment.origin.z;
    debug[index].cuts = max(debug[index].cuts, intercount);
    debug[index].point = 5.0;
    for (int i = 1; i < intercount; i++) {
        MetalVertex mid = MetalVertex{segment.origin.x + dx * (inters[i] + inters[i - 1]) / 2, segment.origin.y + dy * (inters[i] + inters[i - 1]) / 2, segment.origin.z + dz * (inters[i] + inters[i - 1]) / 2};
        debug[index].point = 5.1;
        if (!internal(mid, polygon, debug, index)) {
            debug[index].point = 5.2;
            MetalSegment add = MetalSegment{MetalVertex{segment.origin.x + inters[i - 1] * dx, segment.origin.y + inters[i - 1] * dy, segment.origin.z + inters[i - 1] * dz}, MetalVertex{segment.origin.x + inters[i] * dx, segment.origin.y + inters[i] * dy, segment.origin.z + inters[i] * dz}};
            if (ret.count < 19) {
                ret.segments[ret.count++] = add;
                debug[index].status = max(debug[index].status, 1);
            }
            
        }
        else {
            
            debug[index].status = max(debug[index].status, 2);
            debug[index].drops++;
        }
    }
    return ret;
}

static MetalEdge clip(MetalEdge edge, MetalPolygon polygon, device DebuggeringMetal *debug, int index) {
    debug[index].point = 6.0;
    MetalEdge interim = MetalEdge{{}, 0};
    for (int i = 0; i < edge.count; i++) {
        MetalEdge sub = trim(edge.segments[i], polygon, debug, index);
        debug[index].point = 6.1;
        for (int s = 0; s < sub.count; s++) {
            debug[index].point = 6.2;
            if (interim.count < 19) {
                interim.segments[interim.count++] = sub.segments[s];
                debug[index].code = max(interim.count, debug[index].code);
            }
            
            
        }
    }
    debug[index].point = 100.0;
    return interim;
}

kernel void polygons(device const MetalPolygon *clips [[ buffer(0) ]], device MetalEdge *lines [[ buffer(1) ]], device DebuggeringMetal *debug [[ buffer(2) ]], device const uint2 *bounds [[ buffer(3) ]], uint index [[thread_position_in_grid]]) {
    
    
    
    //If the index is out of bounds, stop before continuing and causing an error
    if (index >= bounds[0].y) {
        return;
    }
    
    //The previous iteration for reference
    MetalEdge edge = lines[index];
    
    for (uint i = 0; i < bounds[0].x; i++) {
        if (i == edge.polygon) {
            continue;
        }
        debug[index].point = 0.1;
        edge = clip(edge, clips[i], debug, index);
        if (edge.count == 0) {
            debug[index].misc = 1.0;
            lines[index] = edge;
            return;
        }
    }
    debug[index].misc = 1.0;
    lines[index] = edge;
}


