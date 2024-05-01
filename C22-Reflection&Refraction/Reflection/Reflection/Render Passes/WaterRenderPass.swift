import MetalKit

struct WaterRenderPass: RenderPass {
    let label = "Water Render Pass"
    var descriptor: MTLRenderPassDescriptor?
    var pipelineState: MTLRenderPipelineState
    let depthStencilState: MTLDepthStencilState?
    var reflectionTexture: MTLTexture?
    var refractionTexture: MTLTexture?
    var depthTexture: MTLTexture?
    weak var shadowTexture: MTLTexture?
    
    init() {
        pipelineState = PipelineStates.createForwardPSO()
        depthStencilState = Self.buildDepthStencilState()
        descriptor = MTLRenderPassDescriptor()
    }
    
    mutating func resize(view: MTKView, size: CGSize) {
        let size = CGSize(
            width: size.width / 2, height: size.height / 2)
        reflectionTexture = Self.makeTexture(
            size: size,
            pixelFormat: view.colorPixelFormat,
            label: "Reflection Texture")
        refractionTexture = Self.makeTexture(
            size: size,
            pixelFormat: view.colorPixelFormat,
            label: "Refraction Texture")
        depthTexture = Self.makeTexture(
            size: size,
            pixelFormat: .depth32Float,
            label: "Refraction Depth Texture")
    }
    
    func render(
        renderEncoder: MTLRenderCommandEncoder,
        scene: GameScene,
        uniforms: Uniforms,
        params: Params
    ) {
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setRenderPipelineState(pipelineState)
        
        var lights = scene.lighting.lights
        renderEncoder.setFragmentBytes(
            &lights,
            length: MemoryLayout<Light>.stride * lights.count,
            index: LightBuffer.index)
        renderEncoder.setFragmentTexture(shadowTexture, index: ShadowTexture.index)
        
        scene.skybox?.update(encoder: renderEncoder)
        
        var params = params
        params.transparency = false
        for model in scene.models {
            model.render(
                encoder: renderEncoder,
                uniforms: uniforms,
                params: params)
        }
        scene.terrain?.render(
            encoder: renderEncoder,
            uniforms: uniforms,
            params: params)
        
        scene.skybox?.render(
            encoder: renderEncoder,
            uniforms: uniforms)
    }
    
    func draw(
        commandBuffer: MTLCommandBuffer,
        scene: GameScene,
        uniforms: Uniforms,
        params: Params
    ) {
        guard let water = scene.water else { return }
        water.reflectionTexture = reflectionTexture
        water.refractionTexture = refractionTexture
        water.refractionDepthTexture = depthTexture
        
        let attachment = descriptor?.colorAttachments[0]
        attachment?.texture = reflectionTexture
        attachment?.storeAction = .store
        let depthAttachment = descriptor?.depthAttachment
        depthAttachment?.texture = depthTexture
        depthAttachment?.storeAction = .store
        guard let descriptor = descriptor,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(
                descriptor: descriptor) else {
            return
        }
        renderEncoder.label = label
        
        var reflectionCamera = scene.camera
        reflectionCamera.rotation.x *= -1
        let position = (scene.camera.position.y - water.position.y) * 2
        reflectionCamera.position.y -= position
        
        var uniforms = uniforms
        uniforms.viewMatrix = reflectionCamera.viewMatrix
        
        var clipPlane = float4(0, 1, 0, -water.position.y)
        uniforms.clipPlane = clipPlane
        
        render(
            renderEncoder: renderEncoder,
            scene: scene,
            uniforms: uniforms,
            params: params)
        renderEncoder.endEncoding()
        
        descriptor.colorAttachments[0].texture = refractionTexture
        guard let refractEncoder = commandBuffer.makeRenderCommandEncoder(
            descriptor: descriptor) else {
            return
        }
        
        refractEncoder.label = "Refraction"
        
        uniforms.viewMatrix = scene.camera.viewMatrix
        clipPlane = float4(0, -1, 0, -water.position.y)
        uniforms.clipPlane = clipPlane
        render(
            renderEncoder: refractEncoder,
            scene: scene,
            uniforms: uniforms,
            params: params)
        refractEncoder.endEncoding()
    }
}
