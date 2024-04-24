#include <metal_stdlib>
using namespace metal;
#import "Common.h"

float calc_distance(
    float3 pointA, float3 pointB,
    float3 camera_position,
    float4x4 modelMatrix)
{
    float3 positionA = (modelMatrix * float4(pointA, 1)).xyz;
    float3 positionB = (modelMatrix * float4(pointB, 1)).xyz;
    float3 midpoint = (positionA + positionB) * 0.5;
    float camera_distance = distance(camera_position, midpoint);
    return camera_distance;
}

kernel void tessellation_main(
    constant float *edge_factors [[buffer(0)]],
    constant float *inside_factors [[buffer(1)]],
    device MTLQuadTessellationFactorsHalf *factors [[buffer(2)]],
    uint pid [[thread_position_in_grid]],
    constant float4 &camera_position [[buffer(3)]],
    constant float4x4 &modelMatrix [[buffer(4)]],
    constant float3* control_points [[buffer(5)]],
    constant Terrain &terrain [[buffer(6)]]
){
    uint index = pid * 4;
    float totalTessellation = 0;
    for (int i = 0; i < 4; i++) {
        int pointAIndex = i;
        int pointBIndex = i + 1;
        if (pointAIndex == 3) {
            pointBIndex = 0;
        }
        int edgeIndex = pointBIndex;
        float cameraDistance = calc_distance(
            control_points[pointAIndex + index],
            control_points[pointBIndex + index],
            camera_position.xyz,
            modelMatrix);
        float tessellation = max(
            4.0,
            terrain.maxTessellation / cameraDistance);
        factors[pid].edgeTessellationFactor[edgeIndex] = tessellation;
        totalTessellation += tessellation;
    }
    
    factors[pid].insideTessellationFactor[0] = totalTessellation * 0.25;
    factors[pid].insideTessellationFactor[1] = totalTessellation * 0.25;
    
}
