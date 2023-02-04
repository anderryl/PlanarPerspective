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

static bool blank(simd_float2 pt) {
    return abs(pt.x + 1) < 0.1 && abs(pt.y + 1) < 0.1;
}

static simd_float2 tangentIntersect(MetalTangent first, MetalTangent second) {
    
    //Find dx and dy vectors for each of the lines
    float deltafy = first.outpost.y - first.origin.y;
    float deltafx = first.outpost.x - first.origin.x;
    float deltasx = second.outpost.x - second.origin.x;
    float deltasy = second.outpost.y - second.origin.y;
    
    //If the line is a point, return exit code zero
    if (deltasx == 0 && deltasy == 0) {
        return {-1, -1};
    }
    
    //Create a 2D matrix from the vectors and calculate the determinant
    float det = deltafx * deltasy - deltasx * deltafy;
    
    //If it is zero or very close, the lines are parallel
    if (abs(det) < 0.01) {
        return {-1, -1};
    }
    
    //The percentage of the length along the segment the intersection occurs
    float ab = ((first.origin.y - second.origin.y) * deltasx - (first.origin.x - second.origin.x) * deltasy) / det;
    float cd = ((first.origin.y - second.origin.y) * deltafx - (first.origin.x - second.origin.x) * deltafy) / det;
    return simd_float2{ab, cd};
}

static simd_float2 intersect(MetalArc arc, MetalTangent player) {
    bool last = false;
    simd_float2 first = {-1, -1};
    for (int i = 0; i < arc.count; i++) {
        MetalTangent tangent = arc.tangents[i];
        simd_float2 intersect = tangentIntersect(player, tangent);
        if (intersect.x >= 0 && intersect.x <= 1 && intersect.y >= 0 && intersect.y <= 1) {
            simd_float2 interpolated = {intersect.x, intersect.y * (tangent.end - tangent.start) + tangent.start};
            if (last) {
                if (interpolated.x < first.x) {
                    return interpolated;
                }
                return first;
            }
            else {
                first = interpolated;
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

bool closer(simd_float2 first, simd_float2 second) {
    float fdist = first.x * first.x + first.y * first.y;
    float sdist = second.x * second.x + second.y * second.y;
    return fdist < sdist;
}

static simd_float2 guardrails(device const MetalArc &arc, device const MetalTangent &player, device const float &radius) {
    MetalArc left = offset(arc, radius, true);
    MetalArc right = offset(arc, radius, false);
    
    simd_float2 linter = intersect(left, player);
    simd_float2 rinter = intersect(right, player);
    
    if (linter.x < 0) {
        if (rinter.x < 0) {
            return {-1, -1};
        }
        
        return rinter.x * (player.outpost - player.origin) + player.origin;
    }
    
    if (rinter.x < 0) {
        return linter.x * (player.outpost - player.origin) + player.origin;
    }
    
    if (linter.x < rinter.x) {
        return linter.x * (player.outpost - player.origin) + player.origin;
    }
    
    return rinter.x * (player.outpost - player.origin) + player.origin;
}

static simd_float2 ends(simd_float2 center, MetalTangent player, device const float &radius) {
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
        simd_float2 contestant = {-1, -1};
        
        //If the collision is on the line, add to the list
        if (min(player.origin.x, player.outpost.x) <= x1 && max(player.origin.x, player.outpost.x) >= x1) {
            if (min(player.origin.y, player.outpost.y) <= y1 && max(player.origin.y, player.outpost.y) >= y1) {
                current = {x1 + center.x, y1 + center.y};
            }
        }
        
        if (min(player.origin.x, player.outpost.x) <= x2 && max(player.origin.x, player.outpost.x) >= x2) {
            if (min(player.origin.y, player.outpost.y) <= y2 && max(player.origin.y, player.outpost.y) >= y2) {
                contestant = {x2 + center.x, y2 + center.y};
            }
        }
        
        if (blank(current)) {
            if (blank(contestant)) {
                return {-1, -1};
            }
            return contestant;
        }
        
        else if (blank(contestant)) {
            return current;
        }
        
        return closer(current, contestant) ? current : contestant;
    }
    
    return {-1, -1};
}

static simd_float2 collision(device const MetalArc &arc, device const MetalTangent &player, device const float &radius) {
    //Do bounds checking
    simd_float2 origin = ends(arc.tangents[0].origin, player, radius);
    simd_float2 outpost = ends(arc.tangents[arc.count - 1].outpost, player, radius);
    //return closer(origin - player.origin, outpost - player.origin) ? origin : outpost;
    simd_float2 rails = guardrails(arc, player, radius);

    if (blank(origin)) {
        if (blank(outpost)) {
            return rails;
        }

        return closer(rails - player.origin, outpost - player.origin) ? rails : outpost;
    }

    else if (blank(outpost)) {
        if (blank(rails)) {
            return origin;
        }

        return closer(origin - player.origin, rails - player.origin) ? origin : rails;
    }

    else if (blank(rails)) {
        return closer(origin - player.origin, outpost - player.origin) ? origin : outpost;
    }

    else {
        if (closer(rails - player.origin, origin - player.origin)) {
            return closer(rails - player.origin, outpost - player.origin) ? rails : outpost;
        }

        return closer(origin - player.origin, outpost - player.origin) ? origin : outpost;
    }
    
    
//    simd_float2 list[3] = {
//        ends(arc.tangents[0].origin, player, radius),
//        ends(arc.tangents[arc.count - 1].outpost, player, radius),
//        guardrails(arc, player, radius)
//    };
//
//    simd_float2 holder = {-1, -1};
//    float record = 100000000;
//
//    for (int i = 0; i < 3; i++) {
//        if (abs(list[i].x + 1) > 0.1 || abs(list[i].y + 1) > 0.1) {
//            simd_float2 offset = list[i] - player.origin;
//            float distance = offset.x * offset.x + offset.y * offset.y;
//            if (distance < record) {
//                record = distance;
//                holder = list[i];
//            }
//        }
//    }
//
//    return holder;
}

kernel void collide(
    device const MetalArc *arcs [[ buffer(0) ]],
    device const MetalTangent &player [[ buffer(1) ]],
    device const uint &bound [[ buffer(2) ]],
    device const float &radius [[ buffer(3) ]],
    device simd_float3 *output [[ buffer(4) ]],
    uint index [[ thread_position_in_grid ]]
) {
    if (index >= bound) {
        output[index] = {-1, -1, -1};
        return;
    }
    
    device const MetalArc &arc = arcs[index];
    simd_float2 intersection = collision(arc, player, radius);
    simd_float2 offset = intersection - player.origin;
    
    if (!blank(intersection)) {
        output[index] = {intersection.x, intersection.y, offset.x * offset.x + offset.y * offset.y};
    }
    
    else {
        output[index] = {-1, -1, -1};
    }
}
