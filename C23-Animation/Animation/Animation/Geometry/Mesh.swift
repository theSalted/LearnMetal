import MetalKit

// swiftlint:disable force_unwrapping
// swiftlint:disable force_cast

struct Mesh {
    var vertexBuffers: [MTLBuffer]
    var submeshes: [Submesh]
    var transform: TransformComponent?
    
    init(
        mdlMesh: MDLMesh,
        mtkMesh: MTKMesh,
        startTime: TimeInterval,
        endTime: TimeInterval
    ) {
        self.init(mdlMesh: mdlMesh, mtkMesh: mtkMesh)
        
        if mdlMesh.transform != nil {
            transform = TransformComponent(
                object: mdlMesh,
                startTime: startTime,
                endTime: endTime)
        }
    }
    
    init(
        mdlMesh: MDLMesh,
        mtkMesh: MTKMesh
    ) {
        var vertexBuffers: [MTLBuffer] = []
        for mtkMeshBuffer in mtkMesh.vertexBuffers {
            vertexBuffers.append(mtkMeshBuffer.buffer)
        }
        self.vertexBuffers = vertexBuffers
        submeshes = zip(mdlMesh.submeshes!, mtkMesh.submeshes).map { mesh in
            Submesh(mdlSubmesh: mesh.0 as! MDLSubmesh, mtkSubmesh: mesh.1)
        }
    }
}

// swiftlint:enable force_unwrapping
// swiftlint:enable force_cast
