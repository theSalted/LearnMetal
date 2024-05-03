import MetalKit

struct Skin {
    var jointPaths: [String] = []
    var skinToSkeletonMap: [Int] = []
    var jointMatrixPaletteBuffer: MTLBuffer
    
    init?(animationBindComponent: MDLAnimationBindComponent?, skeleton: Skeleton?) {
        guard let animationBindComponent, let skeleton else { return nil }
        jointPaths = animationBindComponent.jointPaths ?? skeleton.jointPaths
        skinToSkeletonMap = skeleton.mapJoints(from: jointPaths)
        
        let bufferSize = jointPaths.count * MemoryLayout<float4x4>.stride
        jointMatrixPaletteBuffer = Renderer.device.makeBuffer(length: bufferSize)!
    }
    
    func updatePalette(skeleton: Skeleton?) {
        guard let skeletonPose = skeleton?.currentPose
        else { return }
        var palettePointer = jointMatrixPaletteBuffer.contents().bindMemory(
            to: float4x4.self,
            capacity: jointPaths.count)
        for index in 0..<jointPaths.count {
            let skinIndex = skinToSkeletonMap[index]
            palettePointer.pointee = skeletonPose[skinIndex]
            palettePointer = palettePointer.advanced(by: 1)
        }
    }
}
