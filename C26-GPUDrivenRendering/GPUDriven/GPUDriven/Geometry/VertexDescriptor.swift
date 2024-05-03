import MetalKit

extension MTLVertexDescriptor {
    static var defaultLayout: MTLVertexDescriptor? {
        MTKMetalVertexDescriptorFromModelIO(.defaultLayout)
    }
}

extension MDLVertexDescriptor {
    static var defaultLayout: MDLVertexDescriptor = {
        let vertexDescriptor = MDLVertexDescriptor()
        
        // Position and Normal
        var offset = 0
        vertexDescriptor.attributes[Position.index]
        = MDLVertexAttribute(
            name: MDLVertexAttributePosition,
            format: .float3,
            offset: 0,
            bufferIndex: VertexBuffer.index)
        offset += MemoryLayout<float3>.stride
        vertexDescriptor.attributes[Normal.index] =
        MDLVertexAttribute(
            name: MDLVertexAttributeNormal,
            format: .float3,
            offset: offset,
            bufferIndex: VertexBuffer.index)
        offset += MemoryLayout<float3>.stride
        vertexDescriptor.layouts[VertexBuffer.index]
        = MDLVertexBufferLayout(stride: offset)
        
        // UVs
        vertexDescriptor.attributes[UV.index] =
        MDLVertexAttribute(
            name: MDLVertexAttributeTextureCoordinate,
            format: .float2,
            offset: 0,
            bufferIndex: UVBuffer.index)
        vertexDescriptor.layouts[UVBuffer.index]
        = MDLVertexBufferLayout(stride: MemoryLayout<float2>.stride)
        
        return vertexDescriptor
    }()
}

extension Attributes {
    var index: Int {
        return Int(rawValue)
    }
}

extension BufferIndices {
    var index: Int {
        return Int(rawValue)
    }
}

extension TextureIndices {
    var index: Int {
        return Int(rawValue)
    }
}
