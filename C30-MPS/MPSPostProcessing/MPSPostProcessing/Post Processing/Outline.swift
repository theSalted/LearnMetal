import MetalKit
import MetalPerformanceShaders

struct Outline {
    var outputTexture: MTLTexture!
    
    let label = "Outline"
    
    mutating func resize(view: MTKView, size: CGSize) {
        outputTexture = TextureController.makeTexture(
            size: size,
            pixelFormat: view.colorPixelFormat,
            label: "Output Texture",
            usage: [.shaderRead, .shaderWrite]
        )
    }
    
    mutating func postProcess(
        view: MTKView,
        commandBuffer: MTLCommandBuffer
    ) {
        guard let drawableTexture = view.currentDrawable?.texture else { return
        }
        let sobel = MPSImageSobel(device: Renderer.device)
        sobel.label = "MPS sobel"
        sobel.encode(
            commandBuffer: commandBuffer,
            sourceTexture: drawableTexture,
            destinationTexture: outputTexture)
        let inverse = MPSImageThresholdBinaryInverse(
            device: Renderer.device,
            thresholdValue: 0.4,
            maximumValue: 1.0,
            linearGrayColorTransform: nil
        )
        inverse.encode(
            commandBuffer: commandBuffer,
            sourceTexture: outputTexture,
            destinationTexture: drawableTexture)
    }
}
