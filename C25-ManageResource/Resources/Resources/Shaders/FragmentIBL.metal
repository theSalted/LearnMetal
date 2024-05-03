#include <metal_stdlib>
using namespace metal;
#import "Lighting.h"
#import "ShaderDefs.h"
#import "Material.h"

fragment float4 fragment_IBL(
    VertexOut in [[stage_in]],
    constant Params &params [[buffer(ParamsBuffer)]],
    constant Light *lights [[buffer(LightBuffer)]],
    constant ShaderMaterial &shaderMaterial [[buffer(MaterialBuffer)]],
    depth2d<float> shadowTexture [[texture(ShadowTexture)]],
    texturecube<float> skybox [[texture(SkyboxTexture)]],
    texturecube<float> skyboxDiffuse [[texture(SkyboxDiffuseTexture)]],
    texture2d<float> brdfLut [[texture(BRDFLutTexture)]])
{
    // Load the materials from textures
    constexpr sampler textureSampler(
        filter::linear,
        mip_filter::linear,
        address::repeat);
    Material material = shaderMaterial.material;
    texture2d<float> baseColorTexture = shaderMaterial.baseColorTexture;
    texture2d<float> normalTexture = shaderMaterial.normalTexturel;
    texture2d<float> metallicTexture = shaderMaterial.metallicTexture;
    texture2d<float> roughnessTexture = shaderMaterial.roughnessTexture;
    texture2d<float> aoTexture = shaderMaterial.aoTexture;
    texture2d<float> opacityTexture = shaderMaterial.opacityTexture;
    
    float2 uv = in.uv * params.tiling;
    if (!is_null_texture(baseColorTexture)) {
        float4 color = baseColorTexture.sample(textureSampler, uv);
        material.baseColor = color.rgb;
    }
    if (!is_null_texture(opacityTexture)) {
        if (params.alphaBlending) {
            material.opacity = opacityTexture.sample(textureSampler, uv).r;
        }
        if (params.alphaTesting) {
            material.opacity = opacityTexture.sample(textureSampler, in.uv).r;
            if (material.opacity < 0.2) {
                discard_fragment();
                return(0);
            }
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
    
    // the final result
    float4 color = float4(material.baseColor, 1);
    
    float3 viewDirection =
    in.worldPosition.xyz - params.cameraPosition;
    viewDirection = normalize(viewDirection);
    float3 textureCoordinates =
    reflect(viewDirection, normal);
    
    float4 diffuse = skyboxDiffuse.sample(textureSampler, normal);
    
    diffuse = mix(pow(diffuse, 0.4), diffuse, material.metallic);
    diffuse *= calculateShadow(in.shadowPosition, shadowTexture);
    
    color = diffuse * float4(material.baseColor, 1);
    
    constexpr sampler s(filter::linear, mip_filter::linear);
    float3 prefilteredColor
    = skybox.sample(s,
                    textureCoordinates,
                    level(material.roughness * 10)).rgb;
    float nDotV = saturate(dot(normal, -viewDirection));
    float2 envBRDF
    = brdfLut.sample(s, float2(material.roughness, nDotV)).rg;
    float3 f0 = mix(0.04, material.baseColor.rgb, material.metallic);
    float3 specularIBL = f0 * envBRDF.r + envBRDF.g;
    
    float3 specular = prefilteredColor * specularIBL;
    color += float4(specular, 1);
    color *= material.ambientOcclusion;
    return color;
}
