import Foundation

struct Transform {
    var position: float3 = [0, 0, 0]
    var scale: Float = 1
    var quaternion = simd_quatf(.identity)
    var rotation: float3 = [0, 0, 0] {
        didSet {
            let rotationMatrix = float4x4(rotation: rotation)
            quaternion = simd_quatf(rotationMatrix)
        }
    }
}

extension Transform {
    var modelMatrix: matrix_float4x4 {
        let translation = float4x4(translation: position)
        let rotation = float4x4(quaternion)
        let scale = float4x4(scaling: scale)
        let modelMatrix = translation * rotation * scale
        return modelMatrix
    }
}

protocol Transformable {
    var transform: Transform { get set }
}

extension Transformable {
    var position: float3 {
        get { transform.position }
        set { transform.position = newValue }
    }
    var rotation: float3 {
        get { transform.rotation }
        set { transform.rotation = newValue }
    }
    var scale: Float {
        get { transform.scale }
        set { transform.scale = newValue }
    }
    var quaternion: simd_quatf {
        get { transform.quaternion }
        set { transform.quaternion = newValue }
    }
}
