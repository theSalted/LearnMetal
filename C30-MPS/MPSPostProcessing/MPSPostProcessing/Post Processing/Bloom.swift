import MetalKit
import MetalPerformanceShaders

struct Bloom {
    var outputTexture: MTLTexture!
    var finalTexture: MTLTexture!
    
    let label = "Bloom Filter"
    
    mutating func resize(view: MTKView, size: CGSize) {
        outputTexture = TextureController.makeTexture(
            size: size,
            pixelFormat: view.colorPixelFormat,
            label: "Output Texture",
            usage: [.shaderRead, .shaderWrite]
        )
        finalTexture = TextureController.makeTexture(
            size: size,
            pixelFormat: view.colorPixelFormat,
            label: "Final Texture",
            usage: [.shaderRead, .shaderWrite]
        )
        
    }
    
    mutating func postProcess(
        view: MTKView,
        commandBuffer: MTLCommandBuffer
    ) {
        guard let drawableTexture =
                view.currentDrawable?.texture else { return }
        let brightness = MPSImageThresholdToZero(
            device: Renderer.device,
            thresholdValue: 0.8,
            linearGrayColorTransform: nil)
        brightness.label = "MPS brightness"
        brightness.encode(
            commandBuffer: commandBuffer,
            sourceTexture: drawableTexture,
            destinationTexture: outputTexture)
        let blur = MPSImageGaussianBlur(
            device: Renderer.device,
            sigma: 9.0
        )
        blur.label = "MPS blur"
        blur.encode(
            commandBuffer: commandBuffer,
            inPlaceTexture: &outputTexture,
            fallbackCopyAllocator: nil)
        let add = MPSImageAdd(device: Renderer.device)
        add.encode(
            commandBuffer: commandBuffer,
            primaryTexture: drawableTexture,
            secondaryTexture: outputTexture,
            destinationTexture: finalTexture
        )
        guard let bitEncoder = commandBuffer.makeBlitCommandEncoder() else { return }
        let origin = MTLOrigin(x: 0, y: 0, z: 0)
        let size = MTLSize(
            width: drawableTexture.width,
            height: drawableTexture.height,
            depth: 1)
        bitEncoder.copy(
            from: finalTexture,
            sourceSlice: 0,
            sourceLevel: 0,
            sourceOrigin: origin,
            sourceSize: size,
            to: drawableTexture,
            destinationSlice: 0,
            destinationLevel: 0,
            destinationOrigin: origin
        )
        bitEncoder.endEncoding()
    }
}
