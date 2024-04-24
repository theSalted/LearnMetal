import MetalKit

enum PipelineStates {
    static func createPSO(descriptor: MTLRenderPipelineDescriptor)
    -> MTLRenderPipelineState {
        let pipelineState: MTLRenderPipelineState
        do {
            pipelineState =
            try Renderer.device.makeRenderPipelineState(
                descriptor: descriptor)
        } catch {
            fatalError(error.localizedDescription)
        }
        return pipelineState
    }
    
    static func createComputePSO(function: String)
    -> MTLComputePipelineState {
        guard let kernel = Renderer.library.makeFunction(name: function)
        else { fatalError("Unable to create \(function) PSO") }
        let pipelineState: MTLComputePipelineState
        do {
            pipelineState =
            try Renderer.device.makeComputePipelineState(function: kernel)
        } catch {
            fatalError(error.localizedDescription)
        }
        return pipelineState
    }
    
    static func createRenderPSO(colorPixelFormat: MTLPixelFormat) -> MTLRenderPipelineState {
        let vertexFunction =
        Renderer.library?.makeFunction(name: "vertex_main")
        let fragmentFunction =
        Renderer.library?.makeFunction(name: "fragment_main")
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        // set up vertex descriptor
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<float3>.stride
        vertexDescriptor.layouts[0].stepFunction = .perPatchControlPoint
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.tessellationFactorStepFunction = .perPatch
        pipelineDescriptor.maxTessellationFactor = Renderer.maxTessellation
        pipelineDescriptor.tessellationPartitionMode = .pow2
        return createPSO(descriptor: pipelineDescriptor)
    }
}
