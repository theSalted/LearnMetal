#include <metal_stdlib>
using namespace metal;
#import "Common.h"

kernel void convert_mesh(
    device VertexLayout *vertices [[buffer(0)]],
    uint id [[thread_position_in_grid]],
    device atomic_int &vertexTotal [[buffer(1)]])
{
    vertices[id].position.z = -vertices[id].position.z;
    atomic_fetch_add_explicit(&vertexTotal, 1, memory_order_relaxed);
}

