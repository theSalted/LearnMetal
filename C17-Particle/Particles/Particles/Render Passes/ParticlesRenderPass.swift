import MetalKit

struct ParticlesRenderPass: RenderPass {
    var label: String = "Particle Effects"
    var descriptor: MTLRenderPassDescriptor?
    let computePSO: MTLComputePipelineState
    let renderPSO: MTLRenderPipelineState
    let blendingPSO: MTLRenderPipelineState
    
    var size: CGSize = .zero
    
    init(view: MTKView) {
        computePSO = PipelineStates.createComputePSO(
            function: "computeParticles")
        renderPSO = PipelineStates.createParticleRenderPSO(pixelFormat: view.colorPixelFormat)
        blendingPSO = PipelineStates.createParticleRenderPSO(pixelFormat: view.colorPixelFormat, enableBlending: true)
    }
    
    mutating func resize(view: MTKView, size: CGSize) {
        self.size = size
    }
    
    func update(
        commandBuffer: MTLCommandBuffer,
        scene: GameScene
    ) {
        guard let computerEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        computerEncoder.label = label
        computerEncoder.setComputePipelineState(computePSO)
        let threadsPerGroup = MTLSize(
            width: computePSO.threadExecutionWidth,
            height: 1,
            depth: 1)
        for emitter in scene.particleEffects {
            emitter.emit()
            if emitter.currentParticles <= 0 {
                continue
            }
            let threadsPerGrid = MTLSize(
                width: emitter.particleCount,
                height: 1,
                depth: 1)
            computerEncoder.setBuffer(
                emitter.particleBuffer,
                offset: 0,
                index: 0)
            computerEncoder.dispatchThreads(
                threadsPerGrid,
                threadsPerThreadgroup: threadsPerGroup)
        }
        computerEncoder.endEncoding()
        
    }
    
    func render(
        commandBuffer: MTLCommandBuffer,
        scene: GameScene
    ) {
         guard let descriptor = descriptor,
               let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
        renderEncoder.label = label
        var size: float2 = [Float(size.width), Float(size.height)]
        renderEncoder.setVertexBytes(
            &size,
            length: MemoryLayout<float2>.stride,
            index: 0)
        
        for emitter in scene.particleEffects {
            if emitter.currentParticles <= 0 { continue }
            renderEncoder.setRenderPipelineState(emitter.blending ? blendingPSO : renderPSO)
            renderEncoder.setVertexBuffer(
                emitter.particleBuffer,
                offset: 0,
                index: 1)
            renderEncoder.setVertexBytes(
                &emitter.position,
                length: MemoryLayout<float2>.stride,
                index: 2)
            renderEncoder.setFragmentTexture(
                emitter.particleTexture,
                index: 0)
            renderEncoder.drawPrimitives(
                type: .point,
                vertexStart: 0,
                vertexCount: 1,
                instanceCount: emitter.currentParticles
            )
        }
        renderEncoder.endEncoding()
    }
    
    func draw(
        commandBuffer: MTLCommandBuffer,
        scene: GameScene,
        uniforms: Uniforms,
        params: Params
    ) {
        update(commandBuffer: commandBuffer, scene: scene)
        render(commandBuffer: commandBuffer, scene: scene)
    }
}
