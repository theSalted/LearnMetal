import MetalKit

// Rendering
extension Model {
    func render(
        encoder: MTLRenderCommandEncoder,
        uniforms vertex: Uniforms,
        params fragment: Params,
        renderState: RenderState = .mainPass
    ) {
        encoder.pushDebugGroup(name)
        if let pipelineState {
            let pipelineState = renderState == .mainPass ?
            pipelineState : shadowPipelineState
            if let pipelineState {
                encoder.setRenderPipelineState(pipelineState)
            }
        }
        
        // make the structures mutable
        var uniforms = vertex
        var params = fragment
        params.tiling = tiling
        
        uniforms.modelMatrix = transform.modelMatrix
        uniforms.normalMatrix = uniforms.modelMatrix.upperLeft
        
        encoder.setFragmentBytes(
            &params,
            length: MemoryLayout<Params>.stride,
            index: ParamsBuffer.index)
        
        for mesh in meshes {
            
            setVertexBuffers(encoder: encoder, uniforms: &uniforms, mesh: mesh)
            
            for submesh in mesh.submeshes {
                if submesh.transparency != params.transparency { continue }
                
                if renderState != .shadowPass {
                    encoder.setFragmentBuffer(
                        submesh.materialsBuffer,
                        offset: 0,
                        index: MaterialBuffer.index)

                }
                encoder.drawIndexedPrimitives(
                    type: .triangle,
                    indexCount: submesh.indexCount,
                    indexType: submesh.indexType,
                    indexBuffer: submesh.indexBuffer,
                    indexBufferOffset: submesh.indexBufferOffset
                )
            }
        }
        encoder.popDebugGroup()
    }
    
    func setVertexBuffers(
        encoder: MTLRenderCommandEncoder,
        uniforms: inout Uniforms,
        mesh: Mesh) {
            if let paletteBuffer = mesh.skin?.jointMatrixPaletteBuffer {
                encoder.setVertexBuffer(
                    paletteBuffer,
                    offset: 0,
                    index: JointBuffer.index)
            }
            let currentLocalTransform =
            mesh.transform?.currentTransform ?? .identity
            uniforms.modelMatrix =
            transform.modelMatrix * currentLocalTransform
            uniforms.normalMatrix = uniforms.modelMatrix.upperLeft
            encoder.setVertexBytes(
                &uniforms,
                length: MemoryLayout<Uniforms>.stride,
                index: UniformsBuffer.index)
            
            for (index, vertexBuffer) in mesh.vertexBuffers.enumerated() {
                encoder.setVertexBuffer(
                    vertexBuffer,
                    offset: 0,
                    index: index)
            }
        }
    
    func updateFragmentMaterials(
        encoder: MTLRenderCommandEncoder,
        submesh: Submesh
    ) {
        for (index, texture) in submesh.allTextures.enumerated() {
            encoder.setFragmentTexture(texture, index: index)
        }
        var material = submesh.material
        encoder.setFragmentBytes(
            &material,
            length: MemoryLayout<Material>.stride,
            index: MaterialBuffer.index)
    }
}
