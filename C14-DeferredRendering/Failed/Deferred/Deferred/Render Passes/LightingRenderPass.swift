import MetalKit

struct LightingRenderPass: RenderPass {
    let label = "Lighting Render Pass"
    var descriptor: MTLRenderPassDescriptor?
    var sunLightPSO: MTLRenderPipelineState
    let depthStencilState: MTLDepthStencilState?
    weak var albedoTexture: MTLTexture?
    weak var normalTexture: MTLTexture?
    weak var positionTexture: MTLTexture?
    
    func resize(view: MTKView, size: CGSize) {}
    
    func draw(
        commandBuffer: MTLCommandBuffer,
        scene: GameScene,
        uniforms: Uniforms,
        params: Params) {
        
    }
}
