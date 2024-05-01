import MetalKit

class Water: Transformable {
    let mesh: MTKMesh
    var transform = Transform()
    let pipelineState: MTLRenderPipelineState
    
    var waterMovementTexture: MTLTexture?
    var timer: Float = 0
    
    weak var reflectionTexture: MTLTexture?
    weak var refractionTexture: MTLTexture?
    weak var refractionDepthTexture: MTLTexture?
    
    init() {
        let allocator =
        MTKMeshBufferAllocator(device: Renderer.device)
        let plane = MDLMesh(
            planeWithExtent: [100, 0.2, 100],
            segments: [1, 1],
            geometryType: .triangles,
            allocator: allocator)
        do {
            mesh = try MTKMesh(
                mesh: plane, device: Renderer.device)
        } catch {
            fatalError("failed to create water plane")
        }
        pipelineState = PipelineStates.createWaterPSO(
            vertexDescriptor: MTKMetalVertexDescriptorFromModelIO(
                mesh.vertexDescriptor))
        waterMovementTexture = TextureController.loadTexture(name: "normal-water")
    }
    
    func render(
        encoder: MTLRenderCommandEncoder,
        uniforms: Uniforms,
        params: Params
    ) {
        encoder.pushDebugGroup("Water")
        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(
            mesh.vertexBuffers[0].buffer,
            offset: 0,
            index: 0)
        var uniforms = uniforms
        uniforms.modelMatrix = transform.modelMatrix
        encoder.setVertexBytes(
            &uniforms,
            length: MemoryLayout<Uniforms>.stride,
            index: UniformsBuffer.index)
        
        var params = params
        encoder.setVertexBytes(
            &params,
            length: MemoryLayout<Params>.stride,
            index: ParamsBuffer.index)
        
        let submesh = mesh.submeshes[0]
        
        encoder.setFragmentTexture(
            reflectionTexture,
            index: 0)
        encoder.setFragmentTexture(
            refractionTexture,
            index: 1)
        encoder.setFragmentTexture(
            waterMovementTexture,
            index: 2)
        encoder.setFragmentTexture(
            refractionDepthTexture,
            index: 3)
        
        var timer = timer
        encoder.setFragmentBytes(
            &timer,
            length: MemoryLayout<Float>.size,
            index: 3)
        
        encoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: submesh.indexCount,
            indexType: submesh.indexType,
            indexBuffer: submesh.indexBuffer.buffer,
            indexBufferOffset: 0)
        
        encoder.popDebugGroup()
    }
    
    func update(deltaTime: Float) {
        let sensitivity: Float = 0.005
        timer += deltaTime * sensitivity
    }
}
