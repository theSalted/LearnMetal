#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float3 normal;
};
