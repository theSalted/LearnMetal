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
    
    static func createForwardPSO(hasSkeleton: Bool = false) -> MTLRenderPipelineState {
        let functionConstants = makeFunctionConstants(hasSkeleton: hasSkeleton)
        let vertexFunction = try? Renderer.library?.makeFunction(name: "vertex_main",
            constantValues: functionConstants
        )
        let fragmentFunction =
        Renderer.library?.makeFunction(name: "fragment_main")
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = Renderer.viewColorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        pipelineDescriptor.vertexDescriptor =
        MTLVertexDescriptor.defaultLayout
        return createPSO(descriptor: pipelineDescriptor)
    }
    
    static func makeFunctionConstants(hasSkeleton: Bool) -> MTLFunctionConstantValues {
        let functionConstants = MTLFunctionConstantValues()
        var property = hasSkeleton
        functionConstants.setConstantValue(
            &property,
            type: .bool,
            index: 0)
        return functionConstants
    }
}
