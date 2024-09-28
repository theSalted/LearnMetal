#ifndef Common_h
#define Common_h

#import <simd/simd.h>
#import "stdbool.h"

typedef struct {
    matrix_float4x4 modelMatrix;
    matrix_float4x4 viewMatrix;
    matrix_float4x4 projectionMatrix;
    matrix_float3x3 normalMatrix;
    matrix_float4x4 shadowProjectionMatrix;
    matrix_float4x4 shadowViewMatrix;
} Uniforms;

typedef struct {
    uint32_t width;
    uint32_t height;
    uint32_t tiling;
    uint32_t lightCount;
    vector_float3 cameraPosition;
    float scaleFactor;
    bool alphaTesting;
    bool scissorTesting;
    bool alphaBlending;
    bool antialiasing;
    bool fog;
    bool transparency;
} Params;

typedef enum {
    VertexBuffer = 0,
    UVBuffer = 1,
    TangentBuffer = 2,
    BitangentBuffer = 3,
    UniformsBuffer = 11,
    ParamsBuffer = 12,
    LightBuffer = 13,
    MaterialBuffer = 14,
    ColorBuffer = 20
} BufferIndices;

typedef enum {
    Position = 0,
    Normal = 1,
    UV = 2,
    Tangent = 3,
    Bitangent = 4
} Attributes;

typedef enum {
    BaseColor = 0,
    NormalTexture = 1,
    RoughnessTexture = 2,
    MetallicTexture = 3,
    AOTexture = 4,
    OpacityTexture = 5,
    ShadowTexture = 15
} TextureIndices;

typedef enum {
    unused = 0,
    Sun = 1,
    Spot = 2,
    Point = 3,
    Ambient = 4
} LightType;

typedef struct {
    LightType type;
    vector_float3 position;
    vector_float3 color;
    vector_float3 specularColor;
    float radius;
    vector_float3 attenuation;
    float coneAngle;
    vector_float3 coneDirection;
    float coneAttenuation;
} Light;

typedef struct {
    vector_float3 baseColor;
    float roughness;
    float metallic;
    float ambientOcclusion;
    float opacity;
} Material;

#endif /* Common_h */
