import MetalKit

// swiftlint:disable implicitly_unwrapped_optional

class Renderer: NSObject {
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    static var library: MTLLibrary!
    
    var uniforms = Uniforms()
    var params = Params()
    
    var forwardRenderPass: ForwardRenderPass
//    var fireworks: Fireworks
    var particlesRenderPass: ParticlesRenderPass
    
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
        
        forwardRenderPass = ForwardRenderPass(view: metalView)
//        fireworks = Fireworks()
        particlesRenderPass = ParticlesRenderPass(view: metalView)
        
        self.options = options
        super.init()
        metalView.clearColor = MTLClearColor(
            red: 0.0, green: 0.0, blue: 0.3, alpha: 1.0)
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
        metalView.framebufferOnly = false
    }
}

extension Renderer {
    func mtkView(
        _ view: MTKView,
        drawableSizeWillChange size: CGSize
    ) {
        forwardRenderPass.resize(view: view, size: size)
        particlesRenderPass.resize(view: view, size: size)
    }
    
    func updateUniforms(scene: GameScene) {
        uniforms.viewMatrix = scene.camera.viewMatrix
        uniforms.projectionMatrix = scene.camera.projectionMatrix
        params.lightCount = UInt32(scene.lighting.lights.count)
        params.cameraPosition = scene.camera.position
    }
    
    func draw(scene: GameScene, in view: MTKView) {
        guard
            let commandBuffer = Self.commandQueue.makeCommandBuffer(),
            let descriptor = view.currentRenderPassDescriptor else {
            return
        }
        
        updateUniforms(scene: scene)
        
        forwardRenderPass.descriptor = descriptor
        forwardRenderPass.draw(
            commandBuffer: commandBuffer,
            scene: scene,
            uniforms: uniforms,
            params: params)
        
        // Render Fireworks with compute shaders
//        fireworks.update(size: view.drawableSize)
//        fireworks.draw(commandBuffer: commandBuffer, view: view)
//        
        // Render Particles with compute, vertex and fragment shaders
        particlesRenderPass.descriptor = descriptor
        particlesRenderPass.draw(
            commandBuffer: commandBuffer,
            scene: scene,
            uniforms: uniforms,
            params: params)
        
        guard let drawable = view.currentDrawable else {
            return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

// swiftlint:enable implicitly_unwrapped_optional
