#include <metal_stdlib>
#import "ShaderTypes.h"
using namespace metal;

constant float thresholdLow = 0.00;
constant float thresholdHigh = 1 - thresholdLow;

/*
 Finds and classifies the intersection between two line segments
 
 Exit Codes:
    0 - No Intersect
    1 - Crossing Intersect
    2 - Engulfing Colinearity
    3 - Chaining Colinearity
    4 - Traversing Colinearity
*/
static Intersection intersect(MetalSegment first, MetalSegment second) {
    
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
        
        //Solve the matrix to determine if lines are parallel or colinear
        float dydelx = deltafy * (second.origin.x - first.origin.x);
        float dxdely = deltafx * (second.origin.y - first.origin.y);
        
        //If products aren't equal lines are parallel and there is no solution
        if (dxdely != dydelx) {
            return Intersection{0};
        }
        
        //If not, lines are colinear
        //Find the scalar projection of each of the endpoints of both lines onto the first line's vector
        float2 vec = {deltafx, deltafy};
        float firstOrigin = dot({first.origin.x, first.origin.y}, vec);
        float firstOutpost = dot({first.outpost.x, first.outpost.y}, vec);
        float secondOrigin = dot({second.origin.x, second.origin.y}, vec);
        float secondOutpost = dot({second.outpost.x, second.outpost.y}, vec);
        
        //Sort the projections for each line
        float firstMax = max(firstOrigin, firstOutpost);
        float secondMax = max(secondOrigin, secondOutpost);
        float firstMin = min(firstOrigin, firstOutpost);
        float secondMin = min(secondOrigin, secondOutpost);

        //If either max is smaller than the others min, there is no intersection
        if (firstMax < secondMin || firstMin > secondMax) {
            //Non-Intersectional Colinearity
            return Intersection{0};
        }
        
        //If both of line endpoints are bracketed by the polygon endpoints, line is engulfed
        float secondTotal = secondOutpost - secondOrigin;
        if (firstMax < secondMax && firstMin > secondMin) {
            //Engulfing Colinearity
            //Calculate the alpha values as fractions of projection totals
            return Intersection{2, {0, (firstOrigin - secondOrigin) / secondTotal}, {1, (firstOutpost - secondOrigin) / secondTotal}};
        }
        
        //If both of the polygon endpoints are bracketed by the line endpoints, line traverses
        float firstTotal = firstOutpost - firstOrigin;
        if (firstMax > secondMax && firstMin < secondMin) {
            //Traversing Colinearity
            //Calculate the alpha values as fractions of projection totals
            return Intersection{4, {(secondOrigin - firstOrigin) / firstTotal, 0}, {(secondOutpost - firstOrigin) / firstTotal, 1}};
        }
        
        /*
         If it isn't a colinear non-intersection or an engulfing/traversing intersection, it must be a chaining intersection
         Different logic is required depending if the line is the lower or upper part of the chain
         If the line max is greater than the polygon max, the line is the upper link
        */
        if (firstMax > secondMax && firstMin > secondMin) {
            //Return the alpha coefficients as percentages of projection totals
            return Intersection{3, {firstOrigin == firstMin ? 0.0 : 1.0, (firstMin - secondOrigin) / secondTotal}, {(secondMax - firstOrigin) / firstTotal, secondMax == secondOrigin ? 0.0 : 1.0}};
        }
        
        //If the line max is less than the polygon max, the line is the lower link
        if (firstMax < secondMax && firstMin < secondMin) {
            //Return the alpha coefficients as percentages of projection totals
            return Intersection{3, {firstOrigin == firstMax ? 0.0 : 1.0, (firstMax - secondOrigin) / secondTotal}, {(secondMin - firstOrigin) / firstTotal, secondMin == secondOrigin ? 0.0 : 1.0}};
        }
    }
    
    //The percentage of the length along the segment the intersection occurs
    float ab = ((first.origin.y - second.origin.y) * deltasx - (first.origin.x - second.origin.x) * deltasy) / det;
    float cd = ((first.origin.y - second.origin.y) * deltafx - (first.origin.x - second.origin.x) * deltafy) / det;
    return Intersection{1, {ab, cd}};
}

/*
Determines whether a line penetrates the juncture created by two other segments
*/
static bool penetrates(MetalSegment line, MetalVertex first, MetalVertex second) {
    
    //The vector of the line
    float2 vec = {line.outpost.x - line.origin.x, line.outpost.y - line.origin.y};
    //The offset of the first point
    float2 offOne = {first.x - line.origin.x, first.y - line.origin.y};
    //The component of the first vector on the line vector
    float multOne = dot(offOne, vec) / dot(vec, vec);
    //The error vector of point one
    float2 errorOne = {offOne.x - vec.x * multOne, offOne.y - vec.y * multOne};

    //The offset of the second point
    float2 offTwo = {second.x - line.origin.x, second.y - line.origin.y};
    //The component of the second vector on the line vector
    float multTwo = dot(offTwo, vec) / dot(vec, vec);
    //The error vector of point two
    float2 errorTwo = {offTwo.x - vec.x * multTwo, offTwo.y - vec.y * multTwo};

    //If the two errors point in opposite directions (ei. the line penetrates the juncture), the dot product is less than 0
    return dot(errorOne, errorTwo) < 0;
}

/*
Checks whether the bounding boxes of the line and polygon intersect
*/
static bool exclusive(MetalSegment line, MetalPolygon polygon) {
    //Find the maximum and minimum x and y values of the vertices to define bounding box
    float pmaxx = polygon.vertices[0].x;
    float pminx = polygon.vertices[0].x;
    float pmaxy = polygon.vertices[0].y;
    float pminy = polygon.vertices[0].y;
    for (int i = 1; i < polygon.count; i++) {
        MetalVertex vert = polygon.vertices[i];
        if (vert.x > pmaxx) {
            pmaxx = vert.x;
        }
        if (vert.x < pminx) {
            pminx = vert.x;
        }
        if (vert.y > pmaxy) {
            pmaxy = vert.y;
        }
        if (vert.y < pminy) {
            pminy = vert.y;
        }
    }
    
    //If the bounding boxes don't intersect return true
    if ((line.origin.x < pminx && line.outpost.x < pminx) || (line.origin.x > pmaxx && line.outpost.x > pmaxx)) {
        if ((line.origin.y < pminy && line.outpost.y < pminy) || (line.origin.y > pmaxy && line.outpost.y > pmaxy)) {
            return true;
        }
    }
    return false;
}

/*
Determine whether a segment is above a polygon
*/
static bool above(MetalVertex vert, MetalPolygon polygon, device DebuggeringMetal *debug, int index) {
    
    //Find the vectors of the polygon edges
    float dfx = polygon.vertices[1].x - polygon.vertices[0].x;
    float dfy = polygon.vertices[1].y - polygon.vertices[0].y;
    float dfz = polygon.vertices[1].z - polygon.vertices[0].z;
    float dsx = polygon.vertices[2].x - polygon.vertices[0].x;
    float dsy = polygon.vertices[2].y - polygon.vertices[0].y;
    float dsz = polygon.vertices[2].z - polygon.vertices[0].z;
    
    //Calculate the normal vector as the cross product of the edge vectors
    float normalx = dfy * dsz - dsy * dfz;
    float normaly = dsx * dfz - dfx * dsz;
    float normalz = dfx * dsy - dfy * dsx;
    
    //Substitute the normal coefficients and solve for the offset coefficient
    float offset = (-normalx * polygon.vertices[0].x - normaly * polygon.vertices[0].y - normalz * polygon.vertices[0].z);
    
    //Calculate the z value of the polygon plane at the x and y coordinates of the given vertex
    float z = (normalx * vert.x + normaly * vert.y + offset) / -normalz;
    
    //If the vertex is above or approximately equal to the level of the plane
    return vert.z < z || abs(vert.z - z) < 1;
}

/*
 Calculates the intersections with a given polygon and updates the markline with the new intersections
 */
static MetalSegment clip(MetalSegment line, MetalPolygon polygon, device DebuggeringMetal *debug, int index) {
    
    //If there are only two vertices no clipping is nessecary
    int count = polygon.count;
    if (count == 2) {
        return line;
    }
    
    //Allocate arrays to store the intersections and edges
    Intersection stack[20];
    MetalSegment edges[20];
    
    //If the line is a point, return a blank
    if (abs(line.outpost.x - line.origin.x) < 1 && abs(line.outpost.y - line.origin.y) < 1) {
        debug[index].status = 4;
        return {line.origin, line.outpost, {{{0, 1}}, 1}};
    }

    //If the bounding boxes don't intersect, no clipping is nessecary
    if (exclusive(line, polygon)) {
        return line;
    }
    
    //If both endpoints lie above the plane of the polygon, no clipping is nessecary
    if (above(line.origin, polygon, debug, index) && above(line.outpost, polygon, debug, index)) {
        return line;
    }
    
    //Flags for line adjoining the polygon
    int adjoiner = -1;
    
    //Loop through each of the polygons edges
    float dzline = line.outpost.z - line.origin.z;
    for (int i = 0; i < polygon.count; i++) {
        
        //Find the current edge
        MetalSegment edge = {polygon.vertices[i], polygon.vertices[(i + 1) % count]};
        
        //If the edge is a point, the polygon is one dimensional and no clipping is required
        if (edge.origin.x == edge.outpost.x && edge.origin.y == edge.outpost.y) {
            return line;
        }
        
        //Calculate the intersection
        Intersection inter = intersect(line, edge);
        
        //If there is an intersection
        if (inter.code > 0) {
            
            //If the intersection occurs along the lengths of the clipped segment (endpoint exclusive) and clip edge (endpoint inclusive)
            if (inter.intersection.x > thresholdLow && inter.intersection.x < thresholdHigh && inter.intersection.y >= 0 && inter.intersection.y <= 1) {
                
                //Calculate the z values of the line and edge
                float dzedge = edge.outpost.z - edge.origin.z;
                float lz = dzline * inter.intersection.x + line.origin.z;
                float ez = dzedge * inter.intersection.y + edge.origin.z;
                
                //If the line is above with the edge, no clipping required
                if (lz + 1 < ez) {
                    debug[index].status = 69;
                    debug[index].misc = inter.intersection.x;
                    return line;
                }
                
                //If the line is on the edge, set the adjoiner counter
                if (abs(lz - ez) < 1 && inter.code == 1) {
                    
                    //If an adjoiner has already been found, line must lie within plane of polygon and no clipping is required
                    if (adjoiner != -1) {
                        return line;
                    }
                    adjoiner = i;
                }
            }
        }
        
        //Store the intersection and edge
        stack[i] = inter;
        edges[i] = edge;
    }
    
    //Allocate an array to store the marks
    Mark marks[30] = {};
    int mcount = 0;
    debug[index].cuts = mcount;
    
    //The winding number
    int winding = 0;
    
    //Iterate through each of the intersections
    for (int i = 0; i < count; i++) {
        Intersection cross = stack[i];
        
        //If theres a cross intersection
        if (cross.code == 1) {
            float2 hit = cross.intersection;
            
            //If the intersection occurs on the positive end of the line and along the length of the edge including the outpost but excluding the origin
            if (hit.x > thresholdLow && hit.y > thresholdLow && hit.y <= 1) {
                
                //If the hit is within the bounds of the edge not at the endpoints
                if (hit.y < thresholdHigh) {
                    
                    //If the intersection occurs within the bounds of the line, add the intersection to the markline
                    if (hit.x < thresholdHigh) {
                        marks[mcount++] = {hit.x, 1};
                        debug[index].intersections++;
                    }
                    
                    //Increment the winding number
                    winding++;
                }
                
                //The intersection occurs at the outpost
                else {
                    
                    //If the next intersection is a cross, intersection falls under this jurisdiction
                    Intersection next = stack[(i + 1) % count];
                    if (next.code == 1) {
                        
                        /*
                         Because the intersection occurs at a vertex, the puncture test be applied to determine whether the line punctures the junction. If it does, the intersection must be marked and the winding number must be incremented. Otherwise, intersection shouldn't be marked and the winding number doesn't need incremented.
                         */
                        MetalVertex departing = edges[(i + 1) % count].outpost;
                        MetalVertex approaching = edges[i].origin;
                        if (penetrates(line, approaching, departing)) {
                            
                            //If the hit occurs within the bounds of the line, mark the intersection
                            if (hit.x < 1) {
                                marks[mcount++] = {hit.x, 1};
                                debug[index].intersections++;
                            }
                            
                            //Increment the winding number
                            winding++;
                        }
                    }
                }
            }
        }
        
        //If the intersection is an engulfing colinear, return a blank
        if (cross.code == 2) {
            return {line.origin, line.outpost, {{{0, 1}}, 1}};
        }
        
        //If the intersection is traversing/chaining colinear, apply the puncture test
        if (cross.code > 2) {
            
            //Find the approaching and departing edges
            MetalVertex approaching = edges[i - 1 >= 0 ? i - 1 : count - 1].origin;
            MetalVertex departing = edges[(i + 1) % count].outpost;
            
            //If the line penetrates the juncture
            if (penetrates(line, approaching, departing)) {
                
                //If the intersection occurs after the origin
                //Barrier breaking intersection is always stored in the colinear parameter
                if (cross.colinear.x > thresholdLow) {
                    
                    //If the intersection occurs along the length of the line, mark it
                    if (cross.colinear.x < thresholdHigh) {
                        marks[mcount++] = {cross.colinear.x, 1};
                        debug[index].intersections++;
                    }
                    
                    //Increment the winding number
                    winding++;
                }
            }
        }
    }
    
    //If there are no marks
    if (mcount == 0) {
        
        //If the line is interior and the midpoint is above the polygon, return a blank
        MetalVertex midpoint = {(line.origin.x + line.outpost.x) / 2, (line.origin.y + line.outpost.y) / 2, (line.origin.z + line.outpost.z) / 2};
        if (winding % 2 == 1 && !above(midpoint, polygon, debug, index)) {
            return {line.origin, line.outpost, {{{0, 1}}, 1}};
        }
        
        //Otherwise, no clipping required
        return line;
    }
    
    //Bubble sort the marks list
    for (int i = 0; i < mcount - 1; i++) {
        for (int j = 0; j < mcount - 1; j++) {
            if (marks[j].alpha > marks[j + 1].alpha) {
                Mark temp = marks[j + 1];
                marks[j + 1] = marks[j];
                marks[j] = temp;
            }
        }
    }
    
    //Line origin is interior if winding number is odd
    bool interior = winding % 2 == 1;
    
    //Allocate the result markline
    MarkLine result = {{}, 0};
    
    //If the line origin is interior, add a mark at the origin
    if (interior) {
        result.marks[result.count++] = {0, 1};
    }
    
    //Loop through each of the marks
    for (int i = 0; i < mcount; i++) {
        
        //If the subsegment is interior, add an exit mark
        if (interior) {
            result.marks[result.count++] = {marks[i].alpha, -1};
        }
        
        //Otherwise, add an entry mark
        else {
            result.marks[result.count++] = {marks[i].alpha, 1};
        }
        
        //Toggle the interior boolean
        interior = !interior;
    }
    
    //Add all of the existing marks to the result markline
    for (int i = 0; i < line.markline.count; i++) {
        result.marks[result.count++] = {line.markline.marks[i].alpha, line.markline.marks[i].code};
    }
    
    //Bubble sort the marks again
    for (int i = 0; i < result.count - 1; i++) {
        for (int j = 0; j < result.count - 1; j++) {
            if (result.marks[j].alpha > result.marks[j + 1].alpha) {
                Mark temp = result.marks[j + 1];
                result.marks[j + 1] = result.marks[j];
                result.marks[j] = temp;
            }
        }
    }
    
    //Allocate the final markline to store the culled result
    MarkLine final = {{}, 0};
    
    //The total depth counter
    int total = 0;
    
    //Loop through all of the result marks
    for (int i = 0; i < result.count; i++) {
        
        //If the mark is an entry, the total must be exactly zero to be relevant
        if (result.marks[i].code == 1 && total == 0) {
            final.marks[final.count++] = {result.marks[i].alpha, 1};
        }
        
        //If the mark is an exit, the total must be exactly one to be relevant
        else if (result.marks[i].code == -1 && total == 1) {
            final.marks[final.count++] = {result.marks[i].alpha, -1};
        }
        
        //Add the code to the total counter
        total += result.marks[i].code;
    }

    //Return the final result
    return MetalSegment{line.origin, line.outpost, final};
}

/*
 Returns a list of segments spliced from clipping against the levels polygons
 */
kernel void cliplines(device const MetalPolygon *clips [[ buffer(0) ]], device MetalEdge *lines [[ buffer(1) ]], device DebuggeringMetal *debug [[ buffer(2) ]], device const uint2 *bounds [[ buffer(3) ]], uint index [[thread_position_in_grid]]) {
    
    //If the index is out of bounds, return
    if (index >= bounds[0].y) {
        return;
    }
    
    //The previous iteration for reference
    MetalEdge edge = lines[index];
    MetalSegment segment = edge.segments[0];
    
    //Loop through the clipping polygons
    for (uint i = 0; i < bounds[0].x; i++) {
        
        //If the line belongs to the clipping polygon, skip it
        if (i == edge.polygon) {
            continue;
        }
        
        //Calculate the updated markline against the currentclipping polygon
        segment = clip(segment, clips[i], debug, index);
        debug[index].markline = segment.markline;
        debug[index].point = 50.0;
        
        //If there is only one mark on the line
        if (segment.markline.count == 1) {
            
            //If that mark is a blanking mark, return a blank
            if (segment.markline.marks[0].alpha == 0.0 && segment.markline.marks[0].code == 1.0) {
                lines[index] = {{}, 0, edge.polygon};
                debug[index].point = 100.0;
                debug[index].code = 3;
                return;
            }
        }
    }
    
    //If there are no marks on the line, return the line unaltered
    MarkLine line = segment.markline;
    debug[index].cuts = line.count;
    if (line.count == 0) {
        lines[index] = edge;
        debug[index].point = 100.0;
        debug[index].code = 1;
        return;
    }
    
    //Allocate an empty edge
    MetalEdge final = {{}, 0, edge.polygon};
    
    //Calculate the total segments vectors
    float dx = segment.outpost.x - segment.origin.x;
    float dy = segment.outpost.y - segment.origin.y;
    
    //The alpha value of the beginning of the current segment
    float beginning = 0;
    
    //The total depth of the line under polygons
    int total = 0;
    
    //Iterate through the marks
    for (int i = 0; i < line.count; i++) {
        
        //If not under any polygons and not at the origin, add the current segment
        if (total == 0 && line.marks[i].alpha != 0.0) {
            final.segments[final.count++] = {{dx * beginning + segment.origin.x, dy * beginning + segment.origin.y}, {dx * line.marks[i].alpha + segment.origin.x, dy * line.marks[i].alpha + segment.origin.y}};
        }
        
        //If under polygons
        if (total > 0) {
            debug[index].drops++;
        }
        
        //Reset the beginning alpha
        beginning = line.marks[i].alpha;
        
        //Update the total
        total += line.marks[i].code;
    }
    
    //If external and the beginning alpha is not already at the outpost, add the remainder of the segment
    if (total == 0 && beginning != 1.0) {
        final.segments[final.count++] = {{dx * line.marks[line.count - 1].alpha + segment.origin.x, dy * line.marks[line.count - 1].alpha + segment.origin.y}, segment.outpost, {}};
    }
    debug[index].point = 100.0;
    debug[index].code = 2;
    
    //Return the final result
    lines[index] = final;
}
