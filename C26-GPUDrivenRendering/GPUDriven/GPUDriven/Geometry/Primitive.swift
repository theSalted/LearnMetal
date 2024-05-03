import MetalKit
// swiftlint:disable force_try

enum Primitive {
    case plane, sphere
}

extension Model {
    convenience init(name: String, primitiveType: Primitive) {
        let mdlMesh = Self.createMesh(primitiveType: primitiveType)
        mdlMesh.vertexDescriptor = MDLVertexDescriptor.defaultLayout
        
        // this app expects index type .uint32
        // primitives are created with .uint16
        let mtkMesh: MTKMesh
        if let submeshes = mdlMesh.submeshes as? [MDLSubmesh],
           !submeshes.filter({ $0.indexType == .uint16 }).isEmpty {
            mtkMesh = mdlMesh.convertIndexType(from: .uint16, to: .uint32)
        } else {
            mtkMesh = try! MTKMesh(mesh: mdlMesh, device: Renderer.device)
        }
        
        let mesh = Mesh(mdlMesh: mdlMesh, mtkMesh: mtkMesh)
        self.init()
        self.meshes = [mesh]
        self.name = name
    }
    
    static func createMesh(primitiveType: Primitive) -> MDLMesh {
        let allocator = MTKMeshBufferAllocator(device: Renderer.device)
        switch primitiveType {
        case .plane:
            return MDLMesh(
                planeWithExtent: [1, 1, 1],
                segments: [4, 4],
                geometryType: .triangles,
                allocator: allocator)
        case .sphere:
            return MDLMesh(
                sphereWithExtent: [1, 1, 1],
                segments: [30, 30],
                inwardNormals: false,
                geometryType: .triangles,
                allocator: allocator)
        }
    }
}

// swiftlint:enable force_try

private extension MDLMesh {
    func convertIndexType(from fromType: MDLIndexBitDepth, to toType: MDLIndexBitDepth)
    -> MTKMesh {
        var newSubmeshes: [MDLSubmesh] = []
        if let submeshes = submeshes as? [MDLSubmesh] {
            for submesh in submeshes {
                let indexBuffer = submesh.indexBuffer(asIndexType: toType)
                let newSubmesh = MDLSubmesh(
                    name: submesh.name,
                    indexBuffer: indexBuffer,
                    indexCount: submesh.indexCount,
                    indexType: toType,
                    geometryType: submesh.geometryType,
                    material: submesh.material)
                newSubmeshes.append(newSubmesh)
            }
        }
        let mdlMesh = MDLMesh(
            vertexBuffers: vertexBuffers,
            vertexCount: vertexCount,
            descriptor: vertexDescriptor,
            submeshes: newSubmeshes)
        do {
            return try MTKMesh(mesh: mdlMesh, device: Renderer.device)
        } catch {
            fatalError("Unable to create MTKMesh")
        }
    }
}
