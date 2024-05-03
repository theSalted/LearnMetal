#include <metal_stdlib>
using namespace metal;
#import "Common.h"

struct ICBContainer {
    command_buffer icb [[id(0)]];
};

struct Model {
    constant float *vertexBuffer;
    constant float *uvBuffer;
    constant uint *indexBuffer;
    constant float *materialBuffer;
};

kernel void encodeCommands(
    uint modelIndex [[thread_position_in_grid]],
    device ICBContainer *icbContainer [[buffer(ICBBuffer)]],
    constant Uniforms &uniforms [[buffer(UniformsBuffer)]],
    constant Model *models [[buffer(ModelsBuffer)]],
    constant ModelParams *modelParams [[buffer(ModelParamsBuffer)]],
    constant MTLDrawIndexedPrimitivesIndirectArguments *drawArgumentsBuffer [[buffer(DrawArgumentsBuffer)]])
{
    Model model = models[modelIndex];
    MTLDrawIndexedPrimitivesIndirectArguments drawArguments = drawArgumentsBuffer[modelIndex];
    render_command cmd(icbContainer->icb, modelIndex);
    cmd.set_vertex_buffer(&uniforms, UniformsBuffer);
    cmd.set_vertex_buffer(model.vertexBuffer, VertexBuffer);
    cmd.set_vertex_buffer(model.uvBuffer, UVBuffer);
    cmd.set_vertex_buffer(modelParams, ModelParamsBuffer);
    cmd.set_fragment_buffer(modelParams, ModelParamsBuffer);
    cmd.set_fragment_buffer(model.materialBuffer, MaterialBuffer);
    cmd.draw_indexed_primitives(
        primitive_type::triangle,
        drawArguments.indexCount,
        model.indexBuffer + drawArguments.indexStart,
        drawArguments.instanceCount,
        drawArguments.baseVertex,
        drawArguments.baseInstance);
}
