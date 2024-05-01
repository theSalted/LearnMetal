import MetalKit

// swiftlint:disable force_try

class Model: Transformable {
    var transform = Transform()
    var meshes: [Mesh] = []
    var name: String = "Untitled"
    var tiling: UInt32 = 1
    var hasTransparency = false
    var boundingBox = MDLAxisAlignedBoundingBox()
    var size: float3 {
        return boundingBox.maxBounds - boundingBox.minBounds
    }
    var currentTime: Float = 0
    
    init() {}
    
    init(name: String) {
        guard let assetURL = Bundle.main.url(
            forResource: name,
            withExtension: nil) else {
            fatalError("Model \(name) not found")
        }
        let allocator = MTKMeshBufferAllocator(device: Renderer.device)
        let asset = MDLAsset(
            url: assetURL,
            vertexDescriptor: .defaultLayout,
            bufferAllocator: allocator)
        asset.loadTextures()
        var mtkMeshes: [MTKMesh] = []
        let mdlMeshes =
        asset.childObjects(of: MDLMesh.self) as? [MDLMesh] ?? []
        _ = mdlMeshes.map { mdlMesh in
            mdlMesh.addTangentBasis(
                forTextureCoordinateAttributeNamed:
                    MDLVertexAttributeTextureCoordinate,
                tangentAttributeNamed: MDLVertexAttributeTangent,
                bitangentAttributeNamed: MDLVertexAttributeBitangent)
            mtkMeshes.append(
                try! MTKMesh(
                    mesh: mdlMesh,
                    device: Renderer.device))
        }
        meshes = zip(mdlMeshes, mtkMeshes).map {
            Mesh(
                mdlMesh: $0.0,
                mtkMesh: $0.1,
                startTime: asset.startTime,
                endTime: asset.endTime
            )
        }
        self.name = name
        hasTransparency = meshes.contains { mesh in
            mesh.submeshes.contains { $0.transparency }
        }
        boundingBox = asset.boundingBox
    }
    
    func update(deltaTime: Float) {
        currentTime += deltaTime
        for index in 0..<meshes.count {
            meshes[index].transform?.getCurrentTransform(at: currentTime)
        }
    }
}

extension Model {
    func setTexture(name: String, type: TextureIndices) {
        if let texture = TextureController.loadTexture(name: name) {
            switch type {
            case BaseColor:
                meshes[0].submeshes[0].textures.baseColor = texture
            default: break
            }
        }
    }
}
// swiftlint:enable force_try
