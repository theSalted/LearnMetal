#include <metal_stdlib>
using namespace metal;
#import "ShaderDefs.h"

vertex VertexOut vertex_main(
    VertexIn in [[stage_in]],
    constant Uniforms &uniforms [[buffer(UniformsBuffer)]])
{
    float4 position =
    uniforms.projectionMatrix * uniforms.viewMatrix
    * uniforms.modelMatrix * in.position;
    float4 worldPosition = uniforms.modelMatrix * in.position;
    
    VertexOut out {
        .position = position,
        .normal = in.normal,
        .uv = in.uv,
        .worldPosition = worldPosition.xyz / worldPosition.w,
        .worldNormal = uniforms.normalMatrix * in.normal,
        .worldTangent = uniforms.normalMatrix * in.tangent,
        .worldBitangent = uniforms.normalMatrix * in.bitangent,
        .shadowPosition =
        uniforms.shadowProjectionMatrix * uniforms.shadowViewMatrix
        * uniforms.modelMatrix * in.position,
        .clip_distance[0] = dot(uniforms.modelMatrix * in.position, uniforms.clipPlane)
    };
    
    
    return out;
}
