#include <metal_stdlib>
using namespace metal;
#import "ShaderDefs.h"
#import "Lighting.h"

fragment float4 fragment_terrain(
    FragmentIn in [[stage_in]],
    constant Params &params [[buffer(ParamsBuffer)]],
    constant Light *lights [[buffer(LightBuffer)]],
    depth2d<float> shadowTexture [[texture(ShadowTexture)]],
    texture2d<float> baseColor [[texture(BaseColor)]],
    texture2d<float> underwaterTexture [[texture(MiscTexture)]])
{
    constexpr sampler default_sampler(filter::linear, address::repeat);
    float4 color;
    float4 grass = baseColor.sample(default_sampler, in.uv * params.tiling);
    color = grass;
    
    float4 underwater = underwaterTexture.sample(
    default_sampler,
    in.uv * params.tiling);
    float lower = -1.3;
    float upper = 0.2;
    float y = in.worldPosition.y;
    float waterHeight = (upper - y) / (upper - lower);
    in.worldPosition.y < lower ?
    (color = underwater) :
    (in.worldPosition.y > upper ?
    (color = grass) :
    (color = mix(grass, underwater, waterHeight))
    );
    
    float3 normal = normalize(in.worldNormal);
    Light light = lights[0];
    float3 lightDirection = normalize(light.position);
    float diffuseIntensity = saturate(dot(lightDirection, normal));
    float maxIntensity = 1;
    float minIntensity = 0.2;
    diffuseIntensity = diffuseIntensity * (maxIntensity - minIntensity) + minIntensity;
    color *= diffuseIntensity;
    color *= calculateShadow(in.shadowPosition, shadowTexture);
    return color;
}


