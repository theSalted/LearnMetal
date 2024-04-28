import MetalKit

struct ForwardRenderPass: RenderPass {
    let label = "Forward Render Pass"
    var descriptor: MTLRenderPassDescriptor?
    
    var pipelineState: MTLRenderPipelineState
    let depthStencilState: MTLDepthStencilState?
    
    weak var shadowTexture: MTLTexture?
    var transparentPSO: MTLRenderPipelineState
    
    var pipelineStateMSAA: MTLRenderPipelineState
    var transparentPSOMSAA: MTLRenderPipelineState
    
    init(view: MTKView) {
        pipelineState = PipelineStates.createForwardPSO(
            colorPixelFormat: view.colorPixelFormat)
        depthStencilState = Self.buildDepthStencilState()
        transparentPSO = PipelineStates.createForwardTransparentPSO(colorPixelFormat: view.colorPixelFormat)
        pipelineStateMSAA = PipelineStates.createForwardPSO_MSAA(
          colorPixelFormat: view.colorPixelFormat)
        transparentPSOMSAA =
          PipelineStates.createForwardTransparentPSO_MSAA(
            colorPixelFormat: view.colorPixelFormat)
    }
    
    mutating func resize(view: MTKView, size: CGSize) {
    }
    
    func draw(
        commandBuffer: MTLCommandBuffer,
        scene: GameScene,
        uniforms: Uniforms,
        params: Params
    ) {
        let pipelineState = params.antialiasing ?
          pipelineStateMSAA : pipelineState
        let transparentPSO = params.antialiasing ?
          transparentPSOMSAA : transparentPSO
        
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
        
        if params.scissorTesting {
            let marginWidth = Int(params.width) / 4
            let marginHeight = Int(params.height) / 4
            let width = Int(params.width) / 2
            let height = Int(params.height) / 2
            let rect = MTLScissorRect(
                x: marginWidth,
                y: marginHeight,
                width: width,
                height: height)
            renderEncoder.setScissorRect(rect)
        }
        
        var params = params
        params.transparency = false
        
        for model in scene.models {
            model.render(
                encoder: renderEncoder,
                uniforms: uniforms,
                params: params)
        }
        
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
                params: params)
        }
        renderEncoder.popDebugGroup()
        
        renderEncoder.endEncoding()
    }
}
