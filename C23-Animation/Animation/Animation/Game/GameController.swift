import MetalKit

class GameController: NSObject {
    var scene: GameScene
    var renderer: Renderer
    var deltaTime: Double = 0
    var lastTime: Double = CFAbsoluteTimeGetCurrent()
    var options: Options
    static var fps: Double = 0
    
    init(metalView: MTKView, options: Options) {
        Self.fps = Double(metalView.preferredFramesPerSecond)
        renderer = Renderer(metalView: metalView, options: options)
        scene = GameScene()
        self.options = options
        super.init()
        metalView.delegate = self
        mtkView(metalView, drawableSizeWillChange: metalView.drawableSize)
    }
}

extension GameController: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        scene.update(size: size)
        renderer.mtkView(view, drawableSizeWillChange: size)
    }
    
    func draw(in view: MTKView) {
        let currentTime = CFAbsoluteTimeGetCurrent()
        let deltaTime = (currentTime - lastTime)
        lastTime = currentTime
        scene.update(deltaTime: Float(deltaTime))
        renderer.draw(scene: scene, in: view)
    }
}
