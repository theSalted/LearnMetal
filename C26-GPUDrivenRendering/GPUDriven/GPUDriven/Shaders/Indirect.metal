#include <metal_stdlib>
using namespace metal;
#import "Common.h"

struct VertexIn {
    float4 position [[attribute(Position)]];
    float3 normal [[attribute(Normal)]];
    float2 uv [[attribute(UV)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
    uint modelIndex [[flat]];
};

vertex VertexOut vertex_indirect(
    const VertexIn in [[stage_in]],
    constant Uniforms &uniforms [[buffer(UniformsBuffer)]],
    constant ModelParams *modelParams [[buffer(ModelParamsBuffer)]],
    uint modelIndex [[base_instance]])
{
    ModelParams model = modelParams[modelIndex];
    float4 position = in.position;
    VertexOut out {
        .position = uniforms.projectionMatrix * uniforms.viewMatrix
            * model.modelMatrix * position,
        .uv = in.uv,
        .modelIndex = modelIndex
    };
    return out;
}

struct ShaderMaterial {
    texture2d<float> baseColorTexture;
    Material material;
};

fragment float4 fragment_indirect(
    constant ModelParams *modelParams [[buffer(ModelParamsBuffer)]],
    VertexOut in [[stage_in]],
    constant ShaderMaterial &shaderMaterial [[buffer(MaterialBuffer)]])
{
    ModelParams model = modelParams[in.modelIndex];
    constexpr sampler textureSampler(
        filter::linear,
        address::repeat,
        mip_filter::linear,
        max_anisotropy(4));
    
    Material material = shaderMaterial.material;
    texture2d<float> baseColorTexture = shaderMaterial.baseColorTexture;
    if (!is_null_texture(baseColorTexture)) {
        material.baseColor = baseColorTexture.sample(
            textureSampler,
            in.uv * model.tiling).rgb;
    }
    return float4(material.baseColor, 1);
}
