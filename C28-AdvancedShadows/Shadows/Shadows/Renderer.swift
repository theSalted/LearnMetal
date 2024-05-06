import MetalKit

class Renderer: NSObject {
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var library: MTLLibrary!
    var pipelineState: MTLComputePipelineState!
    var time: Float = 0
    
    init(metalView: MTKView) {
        guard
            let device = MTLCreateSystemDefaultDevice(),
            let commandQueue = device.makeCommandQueue() else {
            fatalError("GPU not available")
        }
        self.device = device
        self.commandQueue = commandQueue
        self.library = device.makeDefaultLibrary()
        
        metalView.device = device
        
        do {
            guard let kernel = library.makeFunction(name: "compute") else {
                fatalError()
            }
            pipelineState = try device.makeComputePipelineState(function: kernel)
        } catch {
            fatalError()
        }
        super.init()
        metalView.delegate = self
        metalView.framebufferOnly = false
    }
}

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        time += 0.01
        guard
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let drawable = view.currentDrawable,
            let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }
        
        commandEncoder.setComputePipelineState(pipelineState)
        let texture = drawable.texture
        commandEncoder.setTexture(texture, index: 0)
        commandEncoder.setBytes(&time, length: MemoryLayout<Float>.size, index: 0)
        
        let width = pipelineState.threadExecutionWidth
        let height = pipelineState.maxTotalThreadsPerThreadgroup / width
        let threadsPerThreadgroup = MTLSize(
            width: width, height: height, depth: 1)
        let gridWidth = texture.width
        let gridHeight = texture.height
        let threadGroupCount = MTLSize(
            width: (gridWidth + width - 1) / width,
            height: (gridHeight + height - 1) / height,
            depth: 1)
        commandEncoder.dispatchThreadgroups(
            threadGroupCount,
            threadsPerThreadgroup: threadsPerThreadgroup)
        
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
