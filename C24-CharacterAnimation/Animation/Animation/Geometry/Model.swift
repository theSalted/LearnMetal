import MetalKit

// swiftlint:disable force_try

class Model: Transformable {
    var transform = Transform()
    var meshes: [Mesh] = []
    var name: String = "Untitled"
    var tiling: UInt32 = 1
    var boundingBox = MDLAxisAlignedBoundingBox()
    var size: float3 {
        return boundingBox.maxBounds - boundingBox.minBounds
    }
    var currentTime: Float = 0
    var skeleton: Skeleton?
    var animationClips: [String:AnimationClip] = [:]
    var pipelineState: MTLRenderPipelineState!
    
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
            Mesh(
                mdlMesh: $0.0,
                mtkMesh: $0.1,
                startTime: asset.startTime,
                endTime: asset.endTime)
        }
        self.name = name
        boundingBox = asset.boundingBox
        
        loadSkeleton(asset: asset)
        loadSkins(mdlMeshes: mdlMeshes)
        loadAnimations(asset: asset)
        
        animationClips.forEach {
            print("Animation: ", $0.key)
        }
        
        let hasSkeleton = skeleton != nil
        pipelineState = PipelineStates.createForwardPSO(hasSkeleton: hasSkeleton)
        print(skeleton?.jointPaths)
    }
    
    func update(deltaTime: Float) {
        currentTime += deltaTime
        
        if let skeleton,
           let animation = animationClips.first {
            let animationClip = animation.value
            skeleton.updatePose(
                at: currentTime,
                animationClip: animationClip)
        }
        for index in 0..<meshes.count {
            var mesh = meshes[index]
            mesh.transform?.getCurrentTransform(at: currentTime)
            mesh.skin?.updatePalette(skeleton: skeleton)
            meshes[index] = mesh
            
        }
    }
    
    func loadSkeleton(asset: MDLAsset) {
        let skeletons = asset.childObjects(of: MDLSkeleton.self) as? [MDLSkeleton] ?? []
        skeleton = Skeleton(mdlSkeleton: skeletons.first)
    }
    
    func loadSkins(mdlMeshes: [MDLMesh]) {
        for index in 0..<mdlMeshes.count {
            let animationBindComponent = mdlMeshes[index].componentConforming(to: MDLComponent.self) as? MDLAnimationBindComponent
            guard let skeleton else { return }
            let skin = Skin(animationBindComponent: animationBindComponent, skeleton: skeleton)
            meshes[index].skin = skin
        }
    }
    
    func loadAnimations(asset: MDLAsset) {
        let assetAnimations = asset.animations.objects.compactMap {
            $0 as? MDLPackedJointAnimation
        }
        for assetAnimation in assetAnimations {
            let animationClip = AnimationClip(animation: assetAnimation)
            animationClips[assetAnimation.name] = animationClip
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
