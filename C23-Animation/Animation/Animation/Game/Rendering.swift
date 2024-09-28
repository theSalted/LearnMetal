import MetalKit

// Rendering
extension Model {
    @objc func render(
        encoder: MTLRenderCommandEncoder,
        uniforms vertex: Uniforms,
        params fragment: Params
    ) {
        encoder.pushDebugGroup(name)
        // make the structures mutable
        var uniforms = vertex
        var params = fragment
        params.tiling = Int32(tiling)
        
        encoder.setFragmentBytes(
            &params,
            length: MemoryLayout<Params>.stride,
            index: ParamsBuffer.index)
        
        for mesh in meshes {
            let currentLocalTransform = mesh.transform?.currentTransform ?? .identity
            uniforms.modelMatrix = transform.modelMatrix * currentLocalTransform
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
            
            for submesh in mesh.submeshes {
                if submesh.transparency != params.transparency { continue }
                
                var material = submesh.material
                encoder.setFragmentBytes(
                    &material,
                    length: MemoryLayout<Material>.stride,
                    index: MaterialBuffer.index)
                
                setTextures(encoder: encoder, submesh: submesh)
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
    
    func setTextures(
        encoder: MTLRenderCommandEncoder,
        submesh: Submesh
    ) {
        encoder.setFragmentTexture(
            submesh.textures.baseColor,
            index: BaseColor.index)
        
        encoder.setFragmentTexture(
            submesh.textures.normal,
            index: NormalTexture.index)
        
        encoder.setFragmentTexture(
            submesh.textures.roughness,
            index: RoughnessTexture.index)
        
        encoder.setFragmentTexture(
            submesh.textures.metallic,
            index: MetallicTexture.index)
        
        encoder.setFragmentTexture(
            submesh.textures.aoTexture,
            index: AOTexture.index)
        
        encoder.setFragmentTexture(
            submesh.textures.opacity,
            index: OpacityTexture.index)
    }
}
