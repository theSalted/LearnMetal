#include <metal_stdlib>
using namespace metal;

#import "Common.h"

struct VertexIn {
    packed_float3 position;
    packed_float3 normal;
    float2 uv;
};

struct VertexOut {
    float4 position [[position]];
    float3 worldPosition;
    float3 worldNormal;
    float2 uv;
    uint textureID [[flat]];
};

vertex VertexOut vertex_nature(
    constant VertexIn *in [[buffer(0)]],
    uint vertexID [[vertex_id]],
    constant int &vertexCount [[buffer(1)]],
    constant Uniforms *uniforms [[buffer(UniformsBuffer)]],
    constant ModelTransform *model [[buffer(ModelTransformBuffer)]],
    constant NatureInstance *instances [[buffer(InstancesBuffer)]],
    uint instanceID [[instance_id]])
{
    NatureInstance instance = instances[instanceID];
    uint offset = instance.morphTargetID * vertexCount;
    VertexIn vertexIn = in[vertexID + offset];
    
    VertexOut out;
    float4 position = float4(vertexIn.position, 1);
    float3 normal = vertexIn.normal;
    
    out.position = uniforms->projectionMatrix * uniforms->viewMatrix
    * model->modelMatrix * instance.modelMatrix * position;
    out.worldPosition = (model->modelMatrix * position
                         * instance.modelMatrix).xyz;
    out.worldNormal = model->normalMatrix * instance.normalMatrix * normal;
    out.uv = vertexIn.uv;
    out.textureID = instance.textureID;
    return out;
}

constant half3 sunlight = half3(2, 4, -4);

fragment half4 fragment_nature(
    VertexOut in [[stage_in]],
    texture2d_array<float> baseColorTexture [[texture(0)]],
    constant Params &params [[buffer(ParamsBuffer)]])
{
    constexpr sampler s(
        filter::linear,
        address::repeat,
        mip_filter::linear,
        max_anisotropy(8));
    half4 baseColor = half4(baseColorTexture.sample(s, in.uv, in.textureID));
    half3 normal = half3(normalize(in.worldNormal));
    
    half3 lightDirection = normalize(sunlight);
    half diffuseIntensity = saturate(dot(lightDirection, normal));
    half4 color = mix(baseColor*0.5, baseColor*1.5, diffuseIntensity);
    return color;
}

vertex float4 vertex_nature_depth(
    constant VertexIn *in [[buffer(0)]],
    uint vertexID [[vertex_id]],
    constant int &vertexCount [[buffer(1)]],
    constant Uniforms *uniforms [[buffer(UniformsBuffer)]],
    constant ModelTransform *model [[buffer(ModelTransformBuffer)]],
    constant NatureInstance *instances [[buffer(InstancesBuffer)]],
    uint instanceID [[instance_id]])
{
    NatureInstance instance = instances[instanceID];
    uint offset = instance.morphTargetID * vertexCount;
    VertexIn vertexIn = in[vertexID + offset];
    
    float4 position = float4(vertexIn.position, 1);
    
    position = uniforms->shadowProjectionMatrix * uniforms->shadowViewMatrix
    * model->modelMatrix * instance.modelMatrix * position;
    return position;
}
