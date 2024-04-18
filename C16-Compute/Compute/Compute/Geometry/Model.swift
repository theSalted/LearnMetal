import MetalKit

// swiftlint:disable force_try

class Model: Transformable {
    var transform = Transform()
    var meshes: [Mesh] = []
    var name: String = "Untitled"
    var tiling: UInt32 = 1
    
    init() { }
    
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
            Mesh(mdlMesh: $0.0, mtkMesh: $0.1)
        }
        self.name = name
    }
    
    func convertMesh() {
        guard let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder()
        else { return }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let piplineState: MTLComputePipelineState
        do {
            guard let kernelFunction = Renderer.library.makeFunction(name: "convert_mesh") else {
                fatalError("Failed to create kernel function")
            }
            piplineState = try Renderer.device.makeComputePipelineState(function: kernelFunction)
        } catch {
            fatalError(error.localizedDescription)
        }
        computeEncoder.setComputePipelineState(piplineState)
        
        let totalBuffer = Renderer.device.makeBuffer(
            length: MemoryLayout<Int>.stride,
            options: [])
        let vertexTotal = totalBuffer?.contents().bindMemory(to: Int.self, capacity: 1)
        vertexTotal?.pointee = 0
        computeEncoder.setBuffer(totalBuffer, offset: 0, index: 1)
        
        for mesh in meshes {
            let vertexBuffer = mesh.vertexBuffers[VertexBuffer.index]
            computeEncoder.setBuffer(vertexBuffer, offset: 0, index: 0)
            let vertexCount = vertexBuffer.length / MemoryLayout<VertexLayout>.stride
            let threadsPerGroup = MTLSize(
                width: piplineState.threadExecutionWidth,
                height: 1,
                depth: 1)
            let threadsPerGrid = MTLSize(
                width: vertexCount,
                height: 1,
                depth: 1)
            computeEncoder.dispatchThreads(
                threadsPerGrid,
                threadsPerThreadgroup: threadsPerGroup)
            computeEncoder.endEncoding()
        }
        commandBuffer.addCompletedHandler { _ in
            print("Total Vertices:", vertexTotal?.pointee ?? -1)
            print("GPU conversion time:", CFAbsoluteTimeGetCurrent() - startTime)
        }
        commandBuffer.commit()
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
