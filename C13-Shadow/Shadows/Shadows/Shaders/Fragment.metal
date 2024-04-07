#include <metal_stdlib>
using namespace metal;
#import "Lighting.h"
#import "ShaderDefs.h"

fragment float4 fragment_main(
    constant Params &params [[buffer(ParamsBuffer)]],
    VertexOut in [[stage_in]],
    constant Light *lights [[buffer(LightBuffer)]],
    constant Material &_material [[buffer(MaterialBuffer)]],
    texture2d<float> baseColorTexture [[texture(BaseColor)]],
    texture2d<float> normalTexture [[texture(NormalTexture)]],
    texture2d<float> roughnessTexture [[texture(RoughnessTexture)]],
    texture2d<float> metallicTexture [[texture(MetallicTexture)]],
    texture2d<float> aoTexture [[texture(AOTexture)]],
    depth2d<float> shadowTexture [[texture(15)]])
{
    Material material = _material;
    constexpr sampler textureSampler(
        filter::linear,
        mip_filter::linear,
        max_anisotropy(8),
        address::repeat);
    if (!is_null_texture(baseColorTexture)) {
        material.baseColor = baseColorTexture.sample(
            textureSampler,
            in.uv * params.tiling).rgb;
    }
    
    if (!is_null_texture(roughnessTexture)) {
        material.roughness = roughnessTexture.sample(
            textureSampler,
            in.uv * params.tiling).r;
    }
    
    if (!is_null_texture(metallicTexture)) {
        material.metallic = metallicTexture.sample(
            textureSampler,
            in.uv * params.tiling).r;
    }
    
    if (!is_null_texture(aoTexture)) {
        material.ambientOcclusion = aoTexture.sample(
                textureSampler,
                in.uv * params.tiling).r;
    }
    
    float3 normal;
    if (is_null_texture(normalTexture)) {
        normal = in.worldNormal;
    } else {
        normal = normalTexture.sample(
                textureSampler,
                in.uv * params.tiling).rgb;
        normal = normal * 2 - 1;
        normal = float3x3(
            in.worldTangent,
            in.worldBitangent,
            in.worldNormal) * normal;
    }
    normal = normalize(normal);
    
    float3 diffuseColor =
    computeDiffuse(lights, params, material, normal);
    
    float3 specularColor =
    computeSpecular(lights, params, material, normal);
    
    float3 shadowPosition = in.shadowPosition.xyz / in.shadowPosition.w;
    float2 xy = shadowPosition.xy;
    xy = xy * 0.5 + 0.5;
    xy.y = 1 - xy.y;
    
    if (xy.x < 0.0 || xy.x > 1.0 || xy.y < 0.0 || xy.y > 1.0) {
        return float4(1, 0, 0, 1);
    }
    
    xy = saturate(xy);
    
    constexpr sampler s(
        coord::normalized, filter::linear,
        address::clamp_to_edge,
        compare_func:: less);
    float shadow_sample = shadowTexture.sample(s, xy);
    
    if (shadowPosition.z > shadow_sample + 0.001) {
        diffuseColor *= 0.5;
    }
    
    return float4(diffuseColor + specularColor, 1);
}
