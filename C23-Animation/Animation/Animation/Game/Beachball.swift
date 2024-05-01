import Foundation

struct Beachball {
    var ball: Model
    var currentTime: Float = 0
    var ballVelocity: Float = 0
    
    init(model: Model) {
        self.ball = model
        ball.position.y = 3
    }
    
    mutating func update(deltaTime: Float) {
        currentTime += deltaTime
        var animation = Animation()
        animation.translations = ballTranslations
        animation.rotations = ballRotations
        ball.position = animation.getTranslation(at: currentTime) ?? float3(repeating: 0)
        ball.position.y += ball.size.y / 2
        ball.quaternion = animation.getRotation(at: currentTime) ?? simd_quatf()
    }
}
