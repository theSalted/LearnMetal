import MetalKit

// swiftlint:disable implicitly_unwrapped_optional

enum RenderState {
    case shadowPass, mainPass
}

class Renderer: NSObject {
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    static var library: MTLLibrary!
    static var viewColorPixelFormat: MTLPixelFormat!
    
    let options: Options
    
    var uniforms = Uniforms()
    var params = Params()
    
    var indirectRenderPass: IndirectRenderPass
    var forwardRenderPass: ForwardRenderPass
    
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
        Self.viewColorPixelFormat = metalView.colorPixelFormat
        
        indirectRenderPass = IndirectRenderPass()
        forwardRenderPass = ForwardRenderPass()
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
    }
    
    func initialize(_ scene: GameScene) {
        TextureController.heap = TextureController.buildHeap()
        for model in scene.models {
            model.meshes = model.meshes.map { mesh in
                var mesh = mesh
                mesh.submeshes = mesh.submeshes.map { submesh in
                    var submesh = submesh
                    submesh.initializeMaterials()
                    return submesh
                }
                return mesh
            }
        }
        indirectRenderPass.initialize(models: scene.models)
    }
}

extension Renderer {
    func mtkView(
        _ view: MTKView,
        drawableSizeWillChange size: CGSize
    ) {
        indirectRenderPass.resize(view: view, size: size)
        forwardRenderPass.resize(view: view, size: size)
    }
    
    func updateUniforms(scene: GameScene) {
        uniforms.viewMatrix = scene.camera.viewMatrix
        uniforms.projectionMatrix = scene.camera.projectionMatrix
    }
    
    func draw(scene: GameScene, in view: MTKView) {
        guard
            let commandBuffer = Self.commandQueue.makeCommandBuffer(),
            let descriptor = view.currentRenderPassDescriptor else {
            return
        }
        
        updateUniforms(scene: scene)
        
        if options.renderChoice == .indirect {
            indirectRenderPass.descriptor = descriptor
            indirectRenderPass.draw(
                commandBuffer: commandBuffer,
                scene: scene,
                uniforms: uniforms,
                params: params)
        } else {
            forwardRenderPass.descriptor = descriptor
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
