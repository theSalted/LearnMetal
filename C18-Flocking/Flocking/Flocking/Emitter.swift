import MetalKit
// swiftlint:disable force_unwrapping

struct Emitter {
    var particleBuffer: MTLBuffer!
    
    init(
        options: Options,
        size: CGSize,
        device: MTLDevice
    ) {
        let bufferSize = MemoryLayout<Particle>.stride * options.particleCount
        particleBuffer = device.makeBuffer(length: bufferSize)
        var pointer = particleBuffer.contents().bindMemory(
            to: Particle.self,
            capacity: options.particleCount)
        pointer.pointee.velocity = float2(options.predatorSpeed, options.predatorSpeed)
        pointer.pointee.position = float2(
            random(Int(size.width)),
            random(Int(size.height)))
        pointer = pointer.advanced(by: 1)
        for _ in 1..<options.particleCount {
            let xPosition = random(Int(size.width))
            let yPosition = random(Int(size.height))
            let position = float2(xPosition, yPosition)
            pointer.pointee.position = position
            let range: ClosedRange<Float> = -options.maxSpeed...options.maxSpeed
            let velocity = float2(Float.random(in: range), Float.random(in: range))
            pointer.pointee.velocity = velocity
            pointer = pointer.advanced(by: 1)
        }
    }
    
    func random(_ max: Int) -> Float {
        guard max > 0 else { return 0 }
        return Float.random(in: 0..<Float(max))
    }
}
// swiftlint:enable force_unwrapping
