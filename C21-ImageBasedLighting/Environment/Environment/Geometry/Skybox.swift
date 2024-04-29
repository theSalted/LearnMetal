import MetalKit

struct Skybox {
    struct SkySettings {
        var turbidity: Float = 0.15
        var sunElevation: Float = 0.56
        var upperAtmosphereScattering: Float = 0.66
        var groundAlbedo: Float = 0.8
    }
    var skySetting = SkySettings()
    let mesh: MTKMesh
    var skyTexture: MTLTexture?
    var diffuseTexture: MTLTexture?
    var brdfLut: MTLTexture?
    let pipelineState: MTLRenderPipelineState
    let depthStencilState: MTLDepthStencilState?
    
    init(textureName: String?) {
        let allocator = MTKMeshBufferAllocator(device: Renderer.device)
        let cube = MDLMesh(
            boxWithExtent: [1, 1, 1], 
            segments: [1, 1, 1],
            inwardNormals: true,
            geometryType: .triangles,
            allocator: allocator)
        do {
            mesh = try MTKMesh(mesh: cube, device: Renderer.device)
        } catch {
            fatalError("Failed to create skybox mesh")
        }
        pipelineState = PipelineStates.createSkyboxPSO(vertexDescriptor: MTKMetalVertexDescriptorFromModelIO(cube.vertexDescriptor))
        depthStencilState = Self.buildDepthStencilState()
        if let textureName {
            skyTexture = TextureController.loadCubeTexture(imageName: textureName)
            diffuseTexture = TextureController.loadCubeTexture(imageName: "irradiance-6.png")
        } else {
            skyTexture = loadGeneratedSkyboxTexture(dimensions: [256, 256])
        }
        brdfLut = Renderer.buildBRDF()
    }
    
    static func buildDepthStencilState() -> MTLDepthStencilState? {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = .lessEqual
        descriptor.isDepthWriteEnabled = true
        return Renderer.device.makeDepthStencilState(descriptor: descriptor)
    }
    
    func render(
        encoder: MTLRenderCommandEncoder,
        uniforms: Uniforms
    ) {
        encoder.pushDebugGroup("Skybox")
        encoder.setRenderPipelineState(pipelineState)
        encoder.setDepthStencilState(depthStencilState)
        encoder.setVertexBuffer(
            mesh.vertexBuffers[0].buffer,
            offset: 0,
            index: 0)
        var uniforms = uniforms
        uniforms.viewMatrix.columns.3 = [0, 0, 0, 1]
        encoder.setVertexBytes(
            &uniforms,
            length: MemoryLayout<Uniforms>.stride,
            index: UniformsBuffer.index)
        let submesh = mesh.submeshes[0]
        encoder.setFragmentTexture(
            skyTexture,
            index: SkyboxTexture.index)
        encoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: submesh.indexCount,
            indexType: submesh.indexType,
            indexBuffer: submesh.indexBuffer.buffer,
            indexBufferOffset: 0)
        encoder.setFragmentTexture(
            diffuseTexture,
            index: SkyboxDiffuseTexture.index)
        encoder.popDebugGroup()
    }
    
    func update(encoder: MTLRenderCommandEncoder) {
        encoder.setFragmentTexture(
            diffuseTexture,
            index: SkyboxDiffuseTexture.index)
        encoder.setFragmentTexture(
            brdfLut,
            index: BRDFLutTexture.index)
    }
    func loadGeneratedSkyboxTexture(dimensions: SIMD2<Int32>) -> MTLTexture? {
        var texture: MTLTexture?
        let skyTexture = MDLSkyCubeTexture(
            name: "Sky",
            channelEncoding: .float16,
            textureDimensions: dimensions,
            turbidity: skySetting.turbidity,
            sunElevation: skySetting.sunElevation,
            upperAtmosphereScattering: skySetting.upperAtmosphereScattering,
            groundAlbedo: skySetting.groundAlbedo)
        do {
            let textureLoader = MTKTextureLoader(device: Renderer.device)
            texture = try textureLoader.newTexture(
                texture: skyTexture,
                options: nil)
        } catch {
            print(error.localizedDescription)
        }
        return texture
    }
}
