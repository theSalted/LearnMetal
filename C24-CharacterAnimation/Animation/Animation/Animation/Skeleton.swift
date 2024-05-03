import MetalKit

class Skeleton {
    let parentIndices: [Int?]
    let jointPaths: [String]
    let bindTransforms: [float4x4]
    let restTransforms: [float4x4]
    var currentPose: [float4x4] = []
    
    init?(mdlSkeleton: MDLSkeleton?) {
        guard let mdlSkeleton, !mdlSkeleton.jointPaths.isEmpty else { return nil }
        jointPaths = mdlSkeleton.jointPaths
        parentIndices = Skeleton.getParentIndices(jointPaths: jointPaths)
        bindTransforms = mdlSkeleton.jointBindTransforms.float4x4Array
        restTransforms = mdlSkeleton.jointRestTransforms.float4x4Array
    }
    
    static func getParentIndices(jointPaths: [String]) -> [Int?] {
        var parentIndices = [Int?](repeating: nil, count: jointPaths.count)
        for (jointIndex, jointPath) in jointPaths.enumerated() {
            let url = URL(fileURLWithPath: jointPath)
            let parentPath = url.deletingLastPathComponent().relativePath
            parentIndices[jointIndex] = jointPaths.firstIndex {
                $0 == parentPath
            }
        }
        return parentIndices
    }
    
    func mapJoints(from jointPaths: [String]) -> [Int] {
        jointPaths.compactMap { jointPath in
            self.jointPaths.firstIndex(of: jointPath)
        }
    }
    
    func updatePose(
        at currentTime: Float,
        animationClip: AnimationClip)
    {
        let time = fmod(currentTime, animationClip.duration)
        var localPose = [float4x4](
            repeating: .identity,
            count: jointPaths.count)
        for index in 0..<jointPaths.count {
            let pose = animationClip.getPose(
                at: time * animationClip.speed, 
                jointPath: jointPaths[index])
            ?? restTransforms[index]
            localPose[index] = pose
        }
        
        var worldPose: [float4x4] = []
        for index in 0..<parentIndices.count {
            let parentIndex = parentIndices[index]
            let localMatrix = localPose[index]
            if let parentIndex {
                worldPose.append(worldPose[parentIndex] * localMatrix)
            } else {
                worldPose.append(localMatrix)
            }
        }
        
        for index in 0..<worldPose.count {
            worldPose[index] *= bindTransforms[index].inverse
        }
        currentPose = worldPose
    }
}
