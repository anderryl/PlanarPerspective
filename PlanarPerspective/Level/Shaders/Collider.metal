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

constant float radius = 10.0;

static simd_float2 tangentIntersect(MetalTangent first, MetalTangent second) {
    
    //Find dx and dy vectors for each of the lines
    float deltafy = first.outpost.y - first.origin.y;
    float deltafx = first.outpost.x - first.origin.x;
    float deltasx = second.outpost.x - second.origin.x;
    float deltasy = second.outpost.y - second.origin.y;
    
    //If the line is a point, return exit code zero
    if (deltasx == 0 && deltasy == 0) {
        return {0};
    }
    
    //Create a 2D matrix from the vectors and calculate the determinant
    float det = deltafx * deltasy - deltasx * deltafy;
    
    //If it is zero or very close, the lines are parallel
    if (abs(det) < 0.01) {
        return simd_float2{-1, -1};
    }
    
    //The percentage of the length along the segment the intersection occurs
    float ab = ((first.origin.y - second.origin.y) * deltasx - (first.origin.x - second.origin.x) * deltasy) / det;
    float cd = ((first.origin.y - second.origin.y) * deltafx - (first.origin.x - second.origin.x) * deltafy) / det;
    return simd_float2{ab, cd};
}

static simd_float2 intersect(MetalArc arc, MetalTangent player) {
    bool last = false;
    for (int i = 0; i < arc.count; i++) {
        simd_float2 intersect = tangentIntersect(arc.tangents[i], player);
        if (intersect.x >= 0 && intersect.x <= 1 && intersect.y >= 0 && intersect.y <= 1) {
            return intersect;
        }
    }
    
    return {-1, -1};
}

static simd_float2 normal(thread MetalArc &arc, thread MetalTangent &tangent, float time, bool positive) {
    simd_float2 base = arc.a * time * time + arc.b * time + arc.c;
    simd_float2 t = 2 * arc.a * time + arc.b;
    simd_float2 n = {-t[1], t[0]};
    simd_float2 nunit = (positive ? 1 : -1) * radius * n / sqrt(n[0] * n[0] + n[1] * n[1]);
    return nunit + base;
}

static void offset(thread MetalArc &arc, float radius, bool positive) {
    thread MetalTangent &first = arc.tangents[0];
    simd_float2 foff = normal(arc, first, first.start, positive);
    first.origin = foff;
    
    for (int i = 0; i < arc.count; i++) {
        thread MetalTangent &tangent = arc.tangents[i];
        simd_float2 off = normal(arc, tangent, tangent.end, positive);
        tangent.outpost = off;
        if (i < arc.count - 1) {
            arc.tangents[i + 1].origin = off;
        }
    }
    
    thread MetalTangent &last = arc.tangents[arc.count - 1];
    simd_float2 loff = normal(arc, last, last.end, positive);
    last.outpost = loff;
}

bool closer(simd_float2 first, simd_float2 second) {
    float fdist = first[0] * first[0] + first[1] * first[1];
    float sdist = second[0] * second[0] + second[1] * second[1];
    return fdist < sdist;
}

static simd_float2 guardrails(device const MetalArc &arc, device const MetalTangent &player) {
    MetalArc left = arc;
    offset(left, radius, true);
    MetalArc right = arc;
    offset(right, radius, false);
    
    simd_float2 linter = intersect(left, player);
    simd_float2 rinter = intersect(right, player);
    
    if (linter[0] < 0) {
        return rinter;
    }
    
    if (rinter[0] < 0) {
        return linter;
    }
    
    simd_float2 olinter = player.origin - linter;
    simd_float2 orinter = player.origin - rinter;
    
    if (closer(olinter, orinter)) {
        return linter;
    }
    
    return rinter;
}

static simd_float2 ends(simd_float2 center, MetalTangent player) {
    player.origin -= center;
    player.outpost -= center;
    
    simd_float2 displacement = player.outpost - player.origin;
    
    float distsq = displacement[0] * displacement[0] + displacement[1] * displacement[1];
    float d = player.origin[0] * player.outpost[1] - player.outpost[0] * player.origin[1];
    float determinant = radius * radius * distsq - d * d;
    
    if (determinant > 0) {
        int sign = displacement[1] > 0 ? 1.0 : -1.0;
        //Finds the potential collision points of the player line
        float x1 = (d * displacement[1] + sign * displacement[0] * sqrt(determinant)) / distsq;
        float x2 = (d * displacement[1] - sign * displacement[0] * sqrt(determinant)) / distsq;
        float y1 = (-d * displacement[0] + abs(displacement[1]) * sqrt(determinant)) / distsq;
        float y2 = (-d * displacement[0] - abs(displacement[1]) * sqrt(determinant)) / distsq;
        
        simd_float2 current = {-1, -1};
        
        //If the collision is on the line, add to the list
        if (min(player.origin.x, player.outpost.x) <= x1 && max(player.origin.x, player.outpost.x) >= x1) {
            if (min(player.origin.y, player.outpost.y) <= y1 && max(player.origin.y, player.outpost.y) >= y1) {
                current = {x1 + center.x, y1 + center.y};
            }
        }
        if (min(player.origin.x, player.outpost.x) <= x2 && max(player.origin.x, player.outpost.x) >= x2) {
            if (min(player.origin.y, player.outpost.y) <= y2 && max(player.origin.y, player.outpost.y) >= y2) {
                if (closer(player.origin - (simd_float2{x2, y2}), player.origin - (simd_float2{x1, y1}))) {
                    return {x2 + center.x, y2 + center.y};
                }
            }
        }
        
        //Return the list of collisions
        return current;
    }
    
    return {-1, -1};
}

static simd_float2 collision(device const MetalArc &arc, device const MetalTangent &player) {
    simd_float2 guards = guardrails(arc, player);
    simd_float2 origin = ends(arc.tangents[0].origin, player);
    simd_float2 outpost = ends(arc.tangents[arc.count - 1].outpost, player);
    
    if (closer(guards, origin)) {
        if (closer(guards, outpost)) {
            return guards;
        }
        else {
            return outpost;
        }
    }
    else {
        if (closer(origin, outpost)) {
            return origin;
        }
        else {
            return outpost;
        }
    }
}

constant uint bound [[ function_constant(0) ]];

kernel void collide(
    device const MetalArc *arcs [[ buffer(0) ]],
    device const MetalTangent *player [[ buffer(1) ]],
    device simd_float3 *output [[ buffer(2) ]],
    uint index [[ thread_position_in_grid ]]
) {
    if (index >= bound) {
        return;
    }
    
    device const MetalArc &arc = arcs[index];
    simd_float2 intersection = collision(arc, player[0]);
    if (intersection[0] < 0) {
        output[index] = {intersection[0], intersection[1], intersection[0] * intersection[0] + intersection[1] * intersection[1]};
    }
    else {
        output[index] = {-1, -1, -1};
    }
}
