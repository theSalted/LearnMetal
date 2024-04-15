#include <metal_stdlib>
using namespace metal;
#import "Lighting.h"
#import "ShaderDefs.h"

struct GBufferOut {
    float4 albedo [[color(RenderTargetAlbedo)]];
    float4 normal [[color(RenderTargetNormal)]];
    float4 position [[color(RenderTargetPosition)]];
};

fragment GBufferOut fragment_main(
    VertexOut in [[stage_in]],
    depth2d<float> shadowTexture [[texture(ShadowTexture)]],
    constant Material &material [[buffer(MaterialBuffer)]]) 
{
    GBufferOut out;
    out.albedo = float4(material.baseColor, 1.0);
    out.albedo.a = calculateShadow(in.shadowPosition, shadowTexture);
    out.normal = float4(normalize(in.worldNormal), 1.0);
    out.position = float4(in.worldPosition, 1.0);
    return out;

}

 
