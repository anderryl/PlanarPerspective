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

/*
Codes:
-1: Exit Polygon
1: Enter Polygon
*/
typedef struct {
    float alpha;
    int code;
} Mark;

typedef struct {
    Mark marks[30];
    int count;
} MarkLine;

//Wrapper for Edge
typedef struct {
    MetalVertex origin;
    MetalVertex outpost;
    MarkLine markline;
} MetalSegment;

//[Edge] wrapper despite the name
typedef struct {
    MetalSegment segments[20];
    int count;
    unsigned int polygon;
} MetalEdge;

//Debug information container type
typedef struct {
    int intersections;
    int code;
    int drops;
    int cuts;
    int status;
    float misc;
    float comp;
    float point;
    MarkLine markline;
    //MarkLine temp;
} DebuggeringMetal;

typedef struct {
    MetalPolygon children[10];
    int count;
} MetalPolyhedron;

typedef struct {
    int segment;
    float alpha;
    bool type;
} Cut;

struct CutMap {
    Cut cuts[20];
    int count;
    bool obscured;
};

typedef struct {
    int code;
    simd_float2 intersection;
    simd_float2 colinear;
} Intersection;

typedef struct {
    Intersection intersections[20];
    Mark marks[20];
    MarkLine initial;
    MarkLine result;
    MetalEdge scaffold;
} ClipperResource;

#endif /* ShaderTypes_h */
