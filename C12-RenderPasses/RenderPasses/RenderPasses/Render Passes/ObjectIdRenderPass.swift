import MetalKit

struct ObjectIdRenderPass: RenderPass {
    var label = "Object ID Render Pass"
    var descriptor: MTLRenderPassDescriptor?
    var pipelineState: MTLRenderPipelineState
    var depthStencilState: MTLDepthStencilState? 
    var idTexture: MTLTexture?
    var depthTexture: MTLTexture?
    
    init() {
        pipelineState = PipelineStates.createObjectIDPSO()
        descriptor = MTLRenderPassDescriptor()
        depthStencilState = Self.buildDepthStencilState()
    }
    mutating func resize(view: MTKView, size: CGSize) {
        idTexture = Self.makeTexture(
            size: size,
            pixelFormat: .r32Uint,
            label: "Id Texture")
        depthTexture = Self.makeTexture(
            size: size,
            pixelFormat: .depth32Float,
            label: "ID Depth Texture")
    }
    
    func draw(commandBuffer: MTLCommandBuffer, scene: GameScene, uniforms: Uniforms, params: Params) {
        guard let descriptor = descriptor else {
            return
        }
        
        descriptor.colorAttachments[0].texture = idTexture
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].storeAction = .store
        descriptor.depthAttachment.texture = depthTexture
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }
        
        renderEncoder.label = label
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setDepthStencilState(depthStencilState)
        
        for model in scene.models {
            model.render(
                encoder: renderEncoder,
                uniforms: uniforms,
                params: params)
        }
        renderEncoder.endEncoding()
    }
}
