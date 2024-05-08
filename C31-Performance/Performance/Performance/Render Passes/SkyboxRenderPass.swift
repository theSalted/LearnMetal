import MetalKit

struct SkyboxRenderPass: RenderPass {
    let label = "Skybox Render Pass"
    var descriptor: MTLRenderPassDescriptor?
    
    mutating func resize(view: MTKView, size: CGSize) {
    }
    
    func draw(
        commandBuffer: MTLCommandBuffer,
        scene: GameScene,
        uniformsBuffer: MTLBuffer,
        params: Params
    ) {
        descriptor?.depthAttachment.storeAction = .dontCare
        descriptor?.colorAttachments[0].loadAction = .load
        descriptor?.depthAttachment.loadAction = .load
        guard let descriptor = descriptor,
              let renderEncoder =
                commandBuffer.makeRenderCommandEncoder(
                    descriptor: descriptor) else {
            return
        }
        renderEncoder.label = label
        
        if Renderer.cullFaces {
            renderEncoder.setCullMode(.back)
        }
        
        scene.skybox?.render(
            encoder: renderEncoder,
            uniformsBuffer: uniformsBuffer)
        renderEncoder.endEncoding()
    }
}
