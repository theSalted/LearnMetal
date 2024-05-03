#ifndef Material_h
#define Material_h

struct ShaderMaterial {
    texture2d<float> baseColorTexture;
    texture2d<float> normalTexturel;
    texture2d<float> roughnessTexture;
    texture2d<float> metallicTexture;
    texture2d<float> aoTexture;
    texture2d<float> opacityTexture;
    Material material;
};

#endif /* Material_h */
