import CoreGraphics

struct ParticleDescriptor {
    var position: float2 = [0, 0]
    var positionXRange: ClosedRange<Float> = 0...0
    var positionYRange: ClosedRange<Float> = 0...0
    var direction: Float = 0
    var directionRange: ClosedRange<Float> = 0...0
    var speed: Float = 0
    var speedRange: ClosedRange<Float> = 0...0
    var pointSize: Float = 80
    var pointSizeRange: ClosedRange<Float> = 0...0
    var startScale: Float = 0
    var startScaleRange: ClosedRange<Float> = 1...1
    var endScale: Float = 0
    var endScaleRange: ClosedRange<Float>?
    var life: Float = 0
    var lifeRange: ClosedRange<Float> = 1...1
    var color: float4 = [0, 0, 0, 1]
}

enum ParticleEffects {
    static func createFire(size: CGSize) -> Emitter {
        var descriptor = ParticleDescriptor()
        descriptor.position.x = Float(size.width) / 2 - 90
        descriptor.positionXRange = 0...180
        descriptor.direction = Float.pi / 2
        descriptor.directionRange = -0.3...0.3
        descriptor.speed = 3
        descriptor.pointSize = 80
        descriptor.startScale = 0
        descriptor.startScaleRange = 0.5...1.0
        descriptor.endScaleRange = 0...0
        descriptor.life = 180
        descriptor.lifeRange = -50...70
        descriptor.color = float4(1.0, 0.392, 0.1, 0.5)
        return Emitter(
            descriptor,
            texture: "fire",
            particleCount: 1200,
            birthRate: 5,
            birthDelay: 0,
            blending: true)
    }
    static func createSnow(size: CGSize) -> Emitter {
        var descriptor = ParticleDescriptor()
        descriptor.positionXRange = 0...Float(size.width)
        descriptor.direction = -.pi / 2
        descriptor.speedRange = 2...6
        descriptor.pointSizeRange = 80 * 0.5...80
        descriptor.startScale = 0
        descriptor.startScaleRange = 0.2...1.0
        descriptor.life = 500
        descriptor.color = [1, 1, 1, 1]
        return Emitter(
            descriptor,
            texture: "snowflake",
            particleCount: 100,
            birthRate: 1,
            birthDelay: 20)
    }
}
