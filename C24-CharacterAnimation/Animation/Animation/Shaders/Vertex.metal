#include <metal_stdlib>
using namespace metal;
#import "ShaderDefs.h"

constant bool hasSkeleton [[function_constant(0)]];

vertex VertexOut vertex_main(
    VertexIn in [[stage_in]],
    constant Uniforms &uniforms [[buffer(UniformsBuffer)]],
    constant float4x4 *jointMatrices [[buffer(JointBuffer), function_constant(hasSkeleton)]])
{
    float4 position = in.position;
    float4 normal = float4(in.normal, 0);
    
    if (hasSkeleton) {
        float4 weights = in.weights;
        ushort4 joints = in.joints;
        position =
            weights.x * (jointMatrices[joints.x] * position) +
            weights.y * (jointMatrices[joints.y] * position) +
            weights.z * (jointMatrices[joints.z] * position) +
            weights.w * (jointMatrices[joints.w] * position);
        normal =
            weights.x * (jointMatrices[joints.x] * normal) +
            weights.y * (jointMatrices[joints.y] * normal) +
            weights.z * (jointMatrices[joints.z] * normal) +
            weights.w * (jointMatrices[joints.w] * normal);
    }
    
    float4 worldPosition = uniforms.modelMatrix * position;
    VertexOut out {
        .position = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix * position,
        .uv = in.uv,
        .worldPosition = worldPosition.xyz / worldPosition.w,
        .worldNormal = uniforms.normalMatrix * normal.xyz,
        .worldTangent = 0,
        .worldBitangent = 0
    };
    return out;
}
