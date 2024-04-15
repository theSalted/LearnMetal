import MetalKit

// swiftlint:disable implicitly_unwrapped_optional

class Renderer: NSObject {
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    static var library: MTLLibrary!
    
    var uniforms = Uniforms()
    var params = Params()
    
    var shadowRenderPass: ShadowRenderPass
    var forwardRenderPass: ForwardRenderPass
    var gBufferRenderPass: GBufferRenderPass
    
    var shadowCamera = OrthographicCamera()
    
    let options: Options
    
    init(metalView: MTKView, options: Options) {
        guard
            let device = MTLCreateSystemDefaultDevice(),
            let commandQueue = device.makeCommandQueue() else {
            fatalError("GPU not available")
        }
        Self.device = device
        Self.commandQueue = commandQueue
        metalView.device = device
        
        // create the shader function library
        let library = device.makeDefaultLibrary()
        Self.library = library
        
        shadowRenderPass = ShadowRenderPass()
        forwardRenderPass = ForwardRenderPass(view: metalView)
        gBufferRenderPass = GBufferRenderPass(view: metalView)
        
        self.options = options
        super.init()
        metalView.clearColor = MTLClearColor(
            red: 0.93,
            green: 0.97,
            blue: 1.0,
            alpha: 1.0)
        metalView.depthStencilPixelFormat = .depth32Float
        mtkView(
            metalView,
            drawableSizeWillChange: metalView.drawableSize)
        
        // set the device's scale factor
#if os(macOS)
        params.scaleFactor = Float(NSScreen.main?.backingScaleFactor ?? 1)
#elseif os(iOS)
        params.scaleFactor = Float(UIScreen.main.scale)
#endif
    }
}

extension Renderer {
    func mtkView(
        _ view: MTKView,
        drawableSizeWillChange size: CGSize
    ) {
        shadowRenderPass.resize(view: view, size: size)
        forwardRenderPass.resize(view: view, size: size)
        gBufferRenderPass.resize(view: view, size: size)
    }
    
    func updateUniforms(scene: GameScene) {
        uniforms.viewMatrix = scene.camera.viewMatrix
        uniforms.projectionMatrix = scene.camera.projectionMatrix
        params.lightCount = UInt32(scene.lighting.lights.count)
        params.cameraPosition = scene.camera.position
        
        let sun = scene.lighting.lights[0]
        shadowCamera = OrthographicCamera.createShadowCamera(
            using: scene.camera,
            lightPosition: sun.position)
        uniforms.shadowProjectionMatrix = shadowCamera.projectionMatrix
        uniforms.shadowViewMatrix = float4x4(
            eye: shadowCamera.position,
            center: shadowCamera.center,
            up: [0, 1, 0])
    }
    
    func draw(scene: GameScene, in view: MTKView) {
        guard
            let commandBuffer = Self.commandQueue.makeCommandBuffer(),
            let descriptor = view.currentRenderPassDescriptor else {
            return
        }
        
        updateUniforms(scene: scene)
        
        shadowRenderPass.draw(
            commandBuffer: commandBuffer,
            scene: scene,
            uniforms: uniforms,
            params: params)
        
        if options.renderChoice == .deferred {
            gBufferRenderPass.shadowTexture = shadowRenderPass.shadowTexture
            gBufferRenderPass.draw(
                commandBuffer: commandBuffer,
                scene: scene,
                uniforms: uniforms,
                params: params)
        } else {
            forwardRenderPass.shadowTexture = shadowRenderPass.shadowTexture
            forwardRenderPass.draw(
                commandBuffer: commandBuffer,
                scene: scene,
                uniforms: uniforms,
                params: params)
        }
        
        guard let drawable = view.currentDrawable else {
            return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

// swiftlint:enable implicitly_unwrapped_optional
