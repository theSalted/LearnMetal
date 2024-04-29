
#include <metal_stdlib>
using namespace metal;
#import "Common.h"

struct VertexIn {
    float4 position [[attribute(Position)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 textureCoordinates;
};

vertex VertexOut vertex_skybox(
    const VertexIn in [[stage_in]],
    constant Uniforms &uniforms [[buffer(UniformsBuffer)]])
{
    VertexOut out;
    float4x4 vp = uniforms.projectionMatrix * uniforms.viewMatrix;
    out.position = (vp * in.position).xyww;
    out.textureCoordinates = in.position.xyz;
    return out;
}

fragment half4 fragment_skybox(
    VertexOut in [[stage_in]],
    texturecube<half> cubeTexture [[texture(SkyboxTexture)]]) {
    constexpr sampler default_sampler(filter::linear);
    half4 color = cubeTexture.sample(
        default_sampler, 
        in.textureCoordinates);
    return color;
}

