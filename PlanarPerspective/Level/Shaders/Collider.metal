//
//  Collider.metal
//  PlanarPerspective
//
//  Created by Rylie Anderson on 1/28/23.
//  Copyright © 2023 Anderson, Todd W. All rights reserved.
//

#include <metal_stdlib>
#import "ShaderTypes.h"
using namespace metal;

static float tangentIntersect(MetalTangent first, MetalTangent second) {
    
    //Find dx and dy vectors for each of the lines
    float deltafy = first.outpost.y - first.origin.y;
    float deltafx = first.outpost.x - first.origin.x;
    float deltasx = second.outpost.x - second.origin.x;
    float deltasy = second.outpost.y - second.origin.y;
    
    //If the line is a point, return exit code zero
    if (deltasx == 0 && deltasy == 0) {
        return 2;
    }
    
    //Create a 2D matrix from the vectors and calculate the determinant
    float det = deltafx * deltasy - deltasx * deltafy;
    
    //If it is zero or very close, the lines are parallel
    if (abs(det) < 0.01) {
        return 2;
    }
    
    //The percentage of the length along the segment the intersection occurs
    float ab = ((first.origin.y - second.origin.y) * deltasx - (first.origin.x - second.origin.x) * deltasy) / det;
    float cd = ((first.origin.y - second.origin.y) * deltafx - (first.origin.x - second.origin.x) * deltafy) / det;
    if (cd >= 0 && cd <= 1 && ab >= 0 && ab <= 1) {
        return ab;
    }
    
    return 2;
}

static float intersect(MetalArc arc, MetalTangent player) {
    bool last = false;
    float first = -1;
    for (int i = 0; i < arc.count; i++) {
        MetalTangent tangent = arc.tangents[i];
        float intersect = tangentIntersect(player, tangent);
        if (intersect >= 0 && intersect <= 1) {
            if (last) {
                if (intersect < first) {
                    return intersect;
                }
                return first;
            }
            else {
                first = intersect;
                last = true;
            }
        }
    }
    
    return first;
}

static simd_float2 normal(MetalArc arc, MetalTangent tangent, float time, bool positive, float radius) {
    simd_float2 base = time * time * arc.a + time * arc.b + arc.c;
    simd_float2 t = 2 * time * arc.a + arc.b;
    simd_float2 n = {-t.y, t.x};
    simd_float2 nunit = (positive ? 1 : -1) * radius * n / sqrt(n.x * n.x + n.y * n.y);
    return nunit + base;
}

static MetalArc offset(device const MetalArc &arc, float radius, bool positive) {
    MetalArc out;
    out.tangents[0] = arc.tangents[0];
    out.tangents[0].origin = normal(arc, arc.tangents[0], arc.tangents[0].start, positive, radius);
    
    for (int i = 0; i < arc.count; i++) {
        simd_float2 off = normal(arc, arc.tangents[i], arc.tangents[i].end, positive, radius);
        out.tangents[i].outpost = off;
        if (i < arc.count - 1) {
            out.tangents[i + 1] = arc.tangents[i + 1];
            out.tangents[i + 1].origin = off;
        }
    }
    
    simd_float2 off = normal(arc, arc.tangents[arc.count - 1], arc.tangents[arc.count - 1].end, positive, radius);
    out.tangents[arc.count + 1].outpost = off;
    
    out.count = arc.count;
    
    return out;
}

static float guardrails(device const MetalArc &arc, device const MetalTangent &player, device const float &radius) {
    MetalArc left = offset(arc, radius, true);
    MetalArc right = offset(arc, radius, false);
    
    float linter = intersect(left, player);
    float rinter = intersect(right, player);
    
    if (linter > 1 || linter < 0) {
        if (rinter > 1 || rinter < 0) {
            return 2;
        }
        
        return rinter;
    }
    
    if (rinter < 0 || rinter > 1) {
        return linter;
    }
    
    return linter < rinter ? linter : rinter;
}

static float ends(simd_float2 center, MetalTangent player, device const float &radius) {
    player.origin -= center;
    player.outpost -= center;
    
    simd_float2 disp = player.outpost - player.origin;
    
    float distsq = disp.x * disp.x + disp.y * disp.y;
    float d = player.origin.x * player.outpost.y - player.outpost.x * player.origin.y;
    float determinant = radius * radius * distsq - d * d;
    
    if (determinant > 0) {
        int sign = disp[1] > 0 ? 1.0 : -1.0;
        //Finds the potential collision points of the player line
        float x1 = (d * disp[1] + sign * disp[0] * sqrt(determinant)) / distsq;
        float x2 = (d * disp[1] - sign * disp[0] * sqrt(determinant)) / distsq;
        float y1 = (-d * disp[0] + abs(disp[1]) * sqrt(determinant)) / distsq;
        float y2 = (-d * disp[0] - abs(disp[1]) * sqrt(determinant)) / distsq;
        
        simd_float2 offset1 = simd_float2{x1, y1} - player.origin;
        simd_float2 offset2 = simd_float2{x2, y2} - player.origin;
        
        float f = (offset1.x * offset1.x + offset1.y * offset1.y) / distsq;
        float s = (offset2.x * offset2.x + offset2.y * offset2.y) / distsq;
        float first = f >= 0 ? f : 2;
        float second = s >= 0 ? s : 2;
        
        float closest = first < second ? first : second;
        
        return sqrt(closest);
    }
    
    return 2;
}

static float collision(device const MetalArc &arc, device const MetalTangent &player, device const float &radius) {
    //Do bounds checking
    float origin = ends(arc.tangents[0].origin, player, radius);
    float outpost = ends(arc.tangents[arc.count - 1].outpost, player, radius);
    //return closer(origin - player.origin, outpost - player.origin) ? origin : outpost;
    float rails = guardrails(arc, player, radius);

    return origin < outpost ? (origin < rails ? origin : rails) : (outpost < rails ? outpost : rails);
}

kernel void collide(
    device const MetalArc *arcs [[ buffer(0) ]],
    device const MetalTangent &player [[ buffer(1) ]],
    device const uint &bound [[ buffer(2) ]],
    device const float &radius [[ buffer(3) ]],
    device float *output [[ buffer(4) ]],
    uint index [[ thread_position_in_grid ]]
) {
    if (index >= bound) {
        output[index] = 2;
        return;
    }
    
    output[index] = collision(arcs[index], player, radius);
}
