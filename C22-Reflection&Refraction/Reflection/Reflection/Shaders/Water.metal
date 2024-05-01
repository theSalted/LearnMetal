#include <metal_stdlib>
using namespace metal;
#import "Common.h"

struct VertexIn {
    float4 position [[attribute(Position)]];
    float2 uv [[attribute(UV)]];
};

struct VertexOut {
    float4 position [[position]];
    float4 worldPosition;
    float2 uv;
};

vertex VertexOut vertex_water(
    const VertexIn in [[stage_in]],
    constant Uniforms &uniforms [[buffer(UniformsBuffer)]])
{
    float4x4 mvp = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix;
    
    VertexOut out {
        .position = mvp * in.position,
        .uv = in.uv,
        .worldPosition = uniforms.modelMatrix * in.position
    };
    return out;
}

fragment float4 fragment_water(
    VertexOut in [[stage_in]],
    constant Params &params [[buffer(ParamsBuffer)]],
    texture2d<float> reflectionTexture [[texture(0)]],
    texture2d<float> refractionTexture [[texture(1)]],
    texture2d<float> normalTexture [[texture(2)]],
    depth2d<float> depthMap [[texture(3)]],
    constant float& timer [[buffer(3)]])
{
    constexpr sampler s(filter::linear, address::repeat);
    float width = float(reflectionTexture.get_width() * 2.0);
    float height = float(reflectionTexture.get_height() * 2.0);
    float x = in.position.x / width;
    float y = in.position.y / height;
    float2 reflectionCoords = float2(x, 1-y);
    float2 refractionCoords = float2(x, y);
    
    float2 uv = in.uv * 2.0;
    float waveStrength = 0.1;
    
    float far = 100;
    float near = 0.1;
    
    float proj33 = far / (far - near);
    float proj43 = proj33 * -near;
    float depth = depthMap.sample(s, refractionCoords);
    float floorDistance = proj43 / (depth - proj33);
    depth = in.position.z;
    float waterDistance = proj43 / (depth - proj33);
    depth = floorDistance - waterDistance;
    
    float2 rippleX = float2(uv.x + timer, uv.y);
    float2 rippleY = float2(-uv.x, uv.y) + timer;
    float2 ripple = ((normalTexture.sample(s, rippleX).rg * 2.0 - 1.0) +
                     (normalTexture.sample(s, rippleY).rg * 2.0 - 1.0)) * waveStrength;
    
    reflectionCoords += ripple;
    refractionCoords += ripple;
    
    reflectionCoords = clamp(reflectionCoords, 0.001, 0.999);
    refractionCoords = clamp(refractionCoords, 0.001, 0.999);
    
    
    float3 viewVector = normalize(params.cameraPosition - in.worldPosition.xyz);
    float mixRation = dot(viewVector, float3(0, 1, 0));
    
    float4 color = mix(
        reflectionTexture.sample(s, reflectionCoords),
        refractionTexture.sample(s, reflectionCoords),
        mixRation);
    
    color = mix(color, float4(0.0, 0.3, 0.5, 1.0), 0.3);
    color.a = clamp(depth * 0.75, 0.0, 1.0);
    return color;
}

