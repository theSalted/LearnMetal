import MetalKit

struct ForwardRenderPass: RenderPass {
    let label = "Forward Render Pass"
    var descriptor: MTLRenderPassDescriptor?
    
    var pipelineState: MTLRenderPipelineState
    var transparentPSO: MTLRenderPipelineState
    let depthStencilState: MTLDepthStencilState?
    
    weak var shadowTexture: MTLTexture?
    
    init(view: MTKView) {
        pipelineState = PipelineStates.createForwardPSO()
        transparentPSO = PipelineStates.createForwardTransparentPSO()
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
        
        renderEncoder.setFragmentTexture(shadowTexture, index: ShadowTexture.index)
        
        if let heap = TextureController.heap {
            renderEncoder.useHeap(heap, stages: .fragment)
        }
        
        scene.skybox?.update(encoder: renderEncoder)
        
        var params = params
        params.transparency = false
        params.alphaTesting = true
        
        for model in scene.models {
            model.render(
                encoder: renderEncoder,
                uniforms: uniforms,
                params: params,
                renderState: .mainPass)
        }
        
        scene.skybox?.render(
            encoder: renderEncoder,
            uniforms: uniforms)
        
        // transparent mesh
        renderEncoder.pushDebugGroup("Transparency")
        let models = scene.models.filter {
            $0.hasTransparency
        }
        params.transparency = true
        if params.alphaBlending {
            renderEncoder.setRenderPipelineState(transparentPSO)
        }
        for model in models {
            model.render(
                encoder: renderEncoder,
                uniforms: uniforms,
                params: params,
                renderState: .mainPass)
        }
        renderEncoder.popDebugGroup()
        
        renderEncoder.endEncoding()
    }
}
