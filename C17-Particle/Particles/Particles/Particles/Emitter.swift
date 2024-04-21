import MetalKit

// swiftlint:disable identifier_name

class Emitter {
    var position: float2 = [0, 0]
    var currentParticles = 0
    var particleCount: Int = 0
    var birthRate: Int
    var birthDelay = 0
    private var birthTimer = 0
    
    var particleTexture: MTLTexture?
    var particleBuffer: MTLBuffer?
    var particleDescriptor: ParticleDescriptor?
    var blending = false
    
    init(
        _ descriptor: ParticleDescriptor,
        texture: String? = "",
        particleCount: Int,
        birthRate: Int,
        birthDelay: Int,
        blending: Bool = false
    ) {
        self.particleDescriptor = descriptor
        self.birthRate = birthRate
        self.birthDelay = birthDelay
        birthTimer = birthDelay
        self.blending = blending
        
        self.particleCount = particleCount
        let bufferSize = MemoryLayout<Particle>.stride * particleCount
        particleBuffer = Renderer.device.makeBuffer(length: bufferSize)
        
        if let texture {
            particleTexture = TextureController.loadTexture(name: texture)
        }
    }
    
    func emit() {
        if currentParticles >= particleCount {
            return
        }
        guard let particleBuffer = particleBuffer,
              let pd = particleDescriptor else {
            return
        }
        birthTimer += 1
        if birthTimer < birthDelay {
            return
        }
        birthTimer = 0
        var pointer = particleBuffer.contents().bindMemory(
            to: Particle.self,
            capacity: particleCount)
        pointer = pointer.advanced(by: currentParticles)
        for _ in 0..<birthRate {
            let positionX = pd.position.x + .random(in: pd.positionXRange)
            let positionY = pd.position.y + .random(in: pd.positionYRange)
            pointer.pointee.position = [positionX, positionY]
            pointer.pointee.startPosition = pointer.pointee.position
            pointer.pointee.size = pd.pointSize + .random(in: pd.pointSizeRange)
            pointer.pointee.direction = pd.direction + .random(in: pd.directionRange)
            pointer.pointee.speed = pd.speed + .random(in: pd.speedRange)
            pointer.pointee.scale = pd.startScale + .random(in: pd.startScaleRange)
            pointer.pointee.startScale = pointer.pointee.scale
            if let range = pd.endScaleRange {
                pointer.pointee.endScale = pd.endScale + .random(in: range)
            } else {
                pointer.pointee.endScale = pointer.pointee.startScale
            }
            
            pointer.pointee.age = 0
            pointer.pointee.life = pd.life + .random(in: pd.lifeRange)
            pointer.pointee.color = pd.color
            pointer = pointer.advanced(by: 1)
        }
        currentParticles += birthRate
    }
    
    struct Particle {
        var position: float2
        var direction: Float
        var speed: Float
        var color: float4
        var life: Float
        var age: Float
        var size: Float
        var scale: Float
        var startScale: Float
        var endScale: Float
        var startPosition: float2
    }
}

// swiftlint:enable identifier_name
