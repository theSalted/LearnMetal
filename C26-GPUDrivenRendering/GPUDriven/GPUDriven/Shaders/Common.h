#ifndef Common_h
#define Common_h

#import <simd/simd.h>

typedef struct {
    matrix_float4x4 modelMatrix;
    matrix_float4x4 viewMatrix;
    matrix_float4x4 projectionMatrix;
    matrix_float3x3 normalMatrix;
} Uniforms;

typedef struct {
    uint32_t tiling;
} Params;

typedef enum {
    VertexBuffer = 0,
    UVBuffer = 1,
    UniformsBuffer = 11,
    ParamsBuffer = 12,
    ModelsBuffer = 13,
    ModelParamsBuffer = 14,
    MaterialBuffer = 15,
    ICBBuffer = 16,
    DrawArgumentsBuffer = 17
} BufferIndices;

typedef enum {
    Position = 0,
    Normal = 1,
    UV = 2,
} Attributes;

typedef enum {
    BaseColor = 0,
} TextureIndices;

typedef struct {
    vector_float3 baseColor;
    float roughness;
    float metallic;
    float ambientOcclusion;
    float opacity;
} Material;

typedef struct {
    matrix_float4x4 modelMatrix;
    matrix_float3x3 normalMatrix;
    uint32_t tiling;
} ModelParams;

#endif /* Common_h */
