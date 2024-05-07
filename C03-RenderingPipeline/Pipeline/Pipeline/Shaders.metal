//
//  Shaders.metal
//  Pipeline
//
//  Created by Yuhao Chen on 3/23/24.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float4 position [[attribute(0)]];
};

vertex float4 vertex_main(const VertexIn vertexIn [[stage_in]]) {
    float4 position = vertexIn.position;
    position.y -= 1.0;
    return position;
}

fragment float4 fragment_main() {
    return float4(0, 0, 1, 1);
}
