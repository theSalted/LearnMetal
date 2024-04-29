#include <metal_stdlib>
using namespace metal;
#import "Lighting.h"
#import "ShaderDefs.h"

float calculateShadow(
                      float4 shadowPosition,
                      depth2d<float> shadowTexture);

fragment float4 fragment_IBL(
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
    texture2d<float> brdfLut [[texture(BRDFLutTexture)]],
    texturecube<float> skybox [[texture(SkyboxTexture)]],
    texturecube<float> skyboxDiffuse [[texture(SkyboxDiffuseTexture)]],
    depth2d<float> shadowTexture [[texture(ShadowTexture)]]
)
{
    // Load the materials from textures
    constexpr sampler textureSampler(
        filter::linear,
        mip_filter::linear,
        address::repeat);
    Material material = _material;
    float2 uv = in.uv * params.tiling;
    if (!is_null_texture(baseColorTexture)) {
        float4 color = baseColorTexture.sample(textureSampler, uv);
        material.baseColor = color.rgb;
    }
    if (params.alphaBlending) {
        if (!is_null_texture(opacityTexture)) {
            material.opacity = opacityTexture.sample(textureSampler, uv).r;
        }
    }
    if (!is_null_texture(roughnessTexture)) {
        material.roughness = roughnessTexture.sample( textureSampler, uv).r;
    }
    if (!is_null_texture(metallicTexture)) {
        material.metallic = metallicTexture.sample(textureSampler, uv).r;
    }
    if (!is_null_texture(aoTexture)) {
        material.ambientOcclusion = aoTexture.sample(textureSampler, uv).r;
    }
    float3 normal;
    if (is_null_texture(normalTexture)) {
        normal = in.worldNormal;
    } else {
        normal = normalTexture.sample(textureSampler, uv).rgb;
        normal = normal * 2 - 1;
        normal = float3x3(
            in.worldTangent,
            in.worldBitangent,
            in.worldNormal) * normal;
    }
    normal = normalize(normal);
    
    float4 color = float4(material.baseColor, 1);
    
    float3 viewDirection = in.worldPosition.xyz - params.cameraPosition;
    viewDirection = normalize(viewDirection);
    float3 textureCoordinates = reflect(viewDirection, normal);
    float4 diffuse = skyboxDiffuse.sample(textureSampler, normal);
    diffuse = mix(pow(diffuse, 0.2), diffuse, material.metallic);
    diffuse *= calculateShadow(in.shadowPosition, shadowTexture);
    color = diffuse * float4(material.baseColor, 1);
    
    constexpr sampler s(filter::linear, mip_filter::linear);
    float3 prefilteredColor = skybox.sample(s, textureCoordinates, level(material.roughness * 10)).rgb;
    float nDotV = saturate(dot(normal, -viewDirection));
    float2 envBRDF = brdfLut.sample(s, float2(material.roughness, nDotV)).rg;
    float3 f0 = mix(0.04, material.baseColor.rgb, material.metallic);
    float3 specularIBL = f0 * envBRDF.r + envBRDF.g;
    float3 specular = prefilteredColor * specularIBL;
    color += float4(specular, 1);
    color *= material.ambientOcclusion;
    return  color;
}
