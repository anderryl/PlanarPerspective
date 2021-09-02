//
//  TakeTwo.metal
//  PlanarPerspective
//
//  Created by Rylie Anderson on 8/20/21.
//  Copyright © 2021 Anderson, Todd W. All rights reserved.
//
/*
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
        if (delta1x == 0) {
            if (first.origin.x == second.origin.x) {
                //colinear
            }
        }
        else {
            float cone = delta1x * first.origin.y - delta1y * first.origin.x;
            float sone = delta2x * second.origin.y - delta2y * first.origin.x;
            if (abs(cone - sone) == 0) {
                //colinear
            }
        }
        
        return {-1, -1};
    }
    
    //If both coefficients are between 1 and 0, there is an intersection
    //The percentage of the length along the segment the intersection occurs
    float ab = ((first.origin.y - second.origin.y) * delta2x - (first.origin.x - second.origin.x) * delta2y) / determinant;
    float cd = ((first.origin.y - second.origin.y) * delta1x - (first.origin.x - second.origin.x) * delta1y) / determinant;
    return {ab, cd};
}

static MetalVertex interpolate(MetalVertex first, MetalVertex second, float alpha) {
    return MetalVertex{first.x + alpha * (second.x - first.x), first.y + alpha * (second.y - first.y), first.z + alpha * (second.z - first.z)};
}

static bool interject(MetalVertex path, MetalVertex first, MetalVertex second) {
    float mags = sqrt(second.x * second.x + second.y * second.y + second.z * second.z);
    float magp = sqrt(path.x * path.x + path.y * path.y + path.z * path.z);
    float dotp = abs(path.x * first.x + path.y * first.y + path.z * first.z) / magp;
    float dots = abs(second.x * first.x + second.y * first.y + second.z * first.z) / mags;
    
    if (dotp > dots) {
        return true;
    }
    return false;
}

static MetalPolyhedron trim(MetalPolygon subject, MetalPolygon clip, device DebuggeringMetal *debug) {
    MetalPolygon subjectMap = MetalPolygon{{}, 0};
    int sconns[20] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    MetalPolygon clipMap = MetalPolygon{{}, 0};
    int cconns[20] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    float calphas[20][5];
    int ccount[20] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    
    int intercount = 0;
    
    for (int si = 0; si < subject.count; si++) {
        subjectMap.vertices[subjectMap.count++] = subject.vertices[si];
        MetalSegment sseg = MetalSegment{subject.vertices[si], subject.vertices[(si + 1) % subject.count]};
        float salphas[5];
        int scount = 0;
        for (int ci = 0; ci < clip.count; ci++) {
            MetalSegment cseg = MetalSegment{clip.vertices[ci], clip.vertices[(ci + 1) % subject.count]};
            float2 inters = intersection(sseg, cseg);
            if (inters.x >= 0 && inters.x <= 1 && inters.y >= 0 && inters.y <= 1) {
                intercount++;
                salphas[scount++] = inters.x;
                calphas[ci][ccount[ci]++] = inters.y;
            }
        }
        
        for (int i = 0; i < scount - 1; i++) {
            for (int j = 0; j < scount - 1; i++) {
                if (salphas[j] > salphas[j + 1]) {
                    float temp = salphas[j];
                    salphas[j] = salphas[j + 1];
                    salphas[j + 1] = temp;
                }
            }
        }
        
        for (int i  = 0; i < scount; i++) {
            subjectMap.vertices[subjectMap.count++] = interpolate(sseg.origin, sseg.outpost, salphas[i]);
        }
    }
    
    for (int total = 0; total < clip.count; total++) {
        for (int i = 0; i < ccount[total] - 1; i++) {
            for (int j = 0; j < ccount[total] - 1; i++) {
                if (calphas[total][j] > calphas[total][j + 1]) {
                    float temp = calphas[total][j];
                    calphas[total][j] = calphas[total][j + 1];
                    calphas[total][j + 1] = temp;
                }
            }
        }
        clipMap.vertices[clipMap.count++] = clip.vertices[total];
        for (int i = 0; i < ccount[total]; i++) {
            clipMap.vertices[clipMap.count++] = interpolate(clip.vertices[total], clip.vertices[(total + 1) % clip.count], calphas[total][i]);
        }
    }
    
    
}

static MetalPolyhedron divide(MetalPolyhedron subject, MetalPolygon clip, device DebuggeringMetal *debug) {
    MetalPolyhedron result = MetalPolyhedron{{}, 0};
    
    for (int i = 0; i < subject.count; i++) {
        MetalPolyhedron children = trim(subject.children[i], clip, debug);
        for (int kids = 0; kids < children.count; kids++) {
            result.children[result.count++] = children.children[kids];
        }
    }
    
    return result;
}

kernel void polygons(device const MetalPolygon *clips [[ buffer(0) ]], device MetalPolygon *subjects [[ buffer(1) ]], device DebuggeringMetal *debug [[ buffer(2) ]], device const uint2 *bounds [[ buffer(3) ]], uint index [[thread_position_in_grid]]) {
    if (index >= bounds[0].y) {
        return;
    }
    
    MetalPolyhedron subject = MetalPolyhedron{{subjects[index]}, 1};
    
    for (uint i = 0; i < bounds[0].x; i++) {
        if (i == index) {
            continue;
        }
        
        if (clips[i].count == 0) {
            return;
        }
        
        subject = divide(subject, clips[i], debug);
    }
}
*/
