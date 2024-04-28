#include <metal_stdlib>
using namespace metal;
#import "Lighting.h"
#import "ShaderDefs.h"

float calculateShadow(
    float4 shadowPosition,
    depth2d<float> shadowTexture);

float4 fog(float4 position, float4 color) {
    float distance = position.z / position.w;
    float density = 0.2;
    float fog = 1.0 - clamp(exp(-density * distance), 0.0, 1.0);
    float4 fogColor = float4(1.0);
    color = mix(color, fogColor, fog);
    return color;
}


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
    texture2d<float> opacityTexture [[texture(OpacityTexture)]],
    depth2d<float> shadowTexture [[texture(ShadowTexture)]])
{
    constexpr sampler textureSampler(
        filter::linear,
        mip_filter::linear,
        address::repeat);
    
    Material material = _material;
    
    float4 color = baseColorTexture.sample(
        textureSampler,
        in.uv * params.tiling);
    if (params.alphaTesting && color.a < 0.1) {
        discard_fragment();
        return 0;
    }
    material.baseColor = color.rgb;
    
    if (params.alphaBlending) {
        if (!is_null_texture(opacityTexture)) {
            material.opacity = opacityTexture.sample(textureSampler, in.uv).r;
        }
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
    computeSpecular(
        lights,
        params,
        material,
        normal);
    
    float shadow = calculateShadow(in.shadowPosition, shadowTexture);
    diffuseColor *= shadow;
    
    float4 c = float4(diffuseColor + specularColor, material.opacity);
    
    if (params.fog) {
        c = fog(in.position, c);
    }
    return c;
}

float calculateShadow(
    float4 shadowPosition,
    depth2d<float> shadowTexture)
{
    // shadow calculation
    float3 position
    = shadowPosition.xyz / shadowPosition.w;
    float2 xy = position.xy;
    xy = xy * 0.5 + 0.5;
    xy.y = 1 - xy.y;
    constexpr sampler s(
        coord::normalized, filter::nearest,
        address::clamp_to_edge,
        compare_func:: less);
    float shadow_sample = shadowTexture.sample(s, xy);
    return (position.z > shadow_sample + 0.001) ? 0.5 : 1;
}

