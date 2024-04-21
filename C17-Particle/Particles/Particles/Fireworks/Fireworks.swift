import MetalKit

struct Fireworks {
    let particleCount = 10000
    let maxEmitter = 8
    var emitters : [FireworksEmitter] = []
    let life: Float = 256
    var timer: Float = 0
    let clearScreenPSO: MTLComputePipelineState
    let fireworksPSO: MTLComputePipelineState
    
    init() {
        clearScreenPSO = PipelineStates.createComputePSO(function: "clearScreen")
        fireworksPSO = PipelineStates.createComputePSO(function: "fireworks")
    }
    
    mutating func update(size: CGSize) {
        timer += 1
        if timer >= 50 {
            timer = 0
            if emitters.count > maxEmitter {
                emitters.removeFirst()
            }
            let emitter = FireworksEmitter(
                particleCount: particleCount,
                size: size,
                life: life)
            emitters.append(emitter)
        }
    }
    
    func draw(
        commandBuffer: MTLCommandBuffer,
        view: MTKView
    ) {
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder(),
              let drawable = view.currentDrawable else {
            return
        }
        
        computeEncoder.setComputePipelineState(clearScreenPSO)
        computeEncoder.setTexture(drawable.texture, index: 0)
        
        var threadsPerGrid = MTLSize(
            width: Int(view.drawableSize.width),
            height: Int(view.drawableSize.height),
            depth: 1)
        
        let width = clearScreenPSO.threadExecutionWidth
        var threadsPerThreadgroup = MTLSize(
            width: width,
            height: clearScreenPSO.maxTotalThreadsPerThreadgroup / width,
            depth: 1)
        computeEncoder.dispatchThreadgroups(
            threadsPerGrid,
            threadsPerThreadgroup: threadsPerThreadgroup)
        computeEncoder.endEncoding()
        
        guard let particleEncoder = commandBuffer.makeComputeCommandEncoder() 
        else { return }
        particleEncoder.setComputePipelineState(fireworksPSO)
        particleEncoder.setTexture(drawable.texture, index: 0)
        
        threadsPerGrid = MTLSize(
            width: particleCount,
            height: 1,
            depth: 1)
        
        for emitter in emitters {
            let particleBuffer = emitter.particleBuffer
            particleEncoder.setBuffer(
                particleBuffer,
                offset: 0,
                index: 0)
            threadsPerThreadgroup = MTLSize(
                width: fireworksPSO.threadExecutionWidth,
                height: 1,
                depth: 1)
            particleEncoder.dispatchThreads(
                threadsPerGrid,
                threadsPerThreadgroup: threadsPerThreadgroup)
        }
        particleEncoder.endEncoding()
    }
}
