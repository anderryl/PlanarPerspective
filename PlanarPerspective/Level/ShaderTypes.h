//
//  ShaderTypes.h
//  PlanarPerspective
//
//  Created by Rylie Anderson on 10/28/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#define NSInteger metal::int32_t
#else
#import <Foundation/Foundation.h>
#endif

#include <simd/simd.h>

//Wrapper for Vertex
typedef struct {
    float x;
    float y;
    float z;
} MetalVertex;

//Wrapper for Polygon
typedef struct {
    MetalVertex vertices[20];
    int count;
} MetalPolygon;

//Wrapper for Edge
typedef struct {
    MetalVertex origin;
    MetalVertex outpost;
} MetalSegment;

//[Edge] wrapper despite the name
typedef struct {
    MetalSegment segments[20];
    int count;
} MetalEdge;

//Debug information container type
typedef struct {
    int intersections;
    int code;
    int drops;
    int cuts;
    int status;
    float misc;
} DebuggeringMetal;

#endif /* ShaderTypes_h */
