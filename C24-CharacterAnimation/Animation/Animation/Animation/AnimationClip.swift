import MetalKit

class AnimationClip {
    let name: String
    var jointAnimation: [String: Animation?] = [:]
    var duration: Float = 0
    var speed: Float = 1
    var jointPaths: [String] = []
    
    init(animation: MDLPackedJointAnimation) {
        self.name = URL(string: animation.name)?.lastPathComponent ?? "Untitled"
        jointPaths = animation.jointPaths
        var duration: Float = 0
        for (jointIndex, jointPath) in animation.jointPaths.enumerated() {
            var jointAnimation = Animation()
            
            // load rotations
            let rotationTimes = animation.rotations.times
            if let lastTime = rotationTimes.last,
               duration < Float(lastTime) {
                duration = Float(lastTime)
            }
            jointAnimation.rotations =
            rotationTimes.enumerated().map { index, time in
                let startIndex = index * animation.jointPaths.count
                let endIndex = startIndex + animation.jointPaths.count
                let array =
                Array(
                    animation.rotations
                        .floatQuaternionArray[startIndex..<endIndex])
                return Keyframe(
                    time: Float(time),
                    value: array[jointIndex])
            }
            
            // load translations
            let translationTimes = animation.translations.times
            if let lastTime = translationTimes.last,
               duration < Float(lastTime) {
                duration = Float(lastTime)
            }
            jointAnimation.translations =
            translationTimes.enumerated().map { index, time in
                let startIndex = index * animation.jointPaths.count
                let endIndex = startIndex + animation.jointPaths.count
                
                let array = Array(animation.translations.float3Array[startIndex..<endIndex])
                return Keyframe(
                    time: Float(time),
                    value: array[jointIndex])
            }
            self.jointAnimation[jointPath] = jointAnimation
        }
        self.duration = duration
    }
    
    func getPose(at time: Float, jointPath: String) -> float4x4? {
        guard let jointAnimation = jointAnimation[jointPath],
              let jointAnimation = jointAnimation
        else { return nil }
        let rotation = jointAnimation.getRotation(at: time) ?? simd_quatf(.identity)
        let translation = jointAnimation.getTranslation(at: time) ?? float3(repeating: 0)
        let pose = float4x4(translation: translation) * float4x4(rotation)
        return pose
    }
}
