import MetalKit

struct ForwardRenderPass: RenderPass {
    let label = "Forward Render Pass"
    var descriptor: MTLRenderPassDescriptor?
    
    var pipelineState: MTLRenderPipelineState
    let depthStencilState: MTLDepthStencilState?
    weak var shadowTexture: MTLTexture?
    
    init(view: MTKView) {
        pipelineState = PipelineStates.createForwardPSO(
            colorPixelFormat: view.colorPixelFormat)
        depthStencilState = Self.buildDepthStencilState()
    }
    
    mutating func resize(view: MTKView, size: CGSize) {
    }
    
    func draw(
        commandBuffer: MTLCommandBuffer,
        scene: GameScene,
        uniforms: Uniforms,
        params: Params
    ) {
        guard let descriptor = descriptor,
              let renderEncoder =
                commandBuffer.makeRenderCommandEncoder(
                    descriptor: descriptor) else {
            return
        }
        renderEncoder.label = label
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setRenderPipelineState(pipelineState)
        
        var lights = scene.lighting.lights
        renderEncoder.setFragmentBytes(
            &lights,
            length: MemoryLayout<Light>.stride * lights.count,
            index: LightBuffer.index)
        
        renderEncoder.setFragmentTexture(
            shadowTexture,
            index: 15)
        
        for model in scene.models {
            model.render(
                encoder: renderEncoder,
                uniforms: uniforms,
                params: params)
        }
        
        // Debugging sun position
        var scene = scene
        DebugModel.debugDrawModel(
            renderEncoder: renderEncoder,
            uniforms: uniforms,
            model: scene.sun,
            color: [0.9, 0.8, 0.2])
        // End Debugging
        
        
        DebugCameraFrustum.draw(
            encoder: renderEncoder,
            scene: scene,
            uniforms: uniforms)
        
        renderEncoder.endEncoding()
    }
}
