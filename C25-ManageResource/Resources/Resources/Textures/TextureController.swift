import MetalKit

enum TextureController {
    static var textureIndex: [String: Int] = [:]
    static var textures: [MTLTexture] = []
    static var heap: MTLHeap?
    
    static func texture(name: String) -> Int? {
        if let index = textureIndex[name] {
            return index
        }
        if let texture = loadTexture(name: name) {
            return store(texture: texture, name: name)
        }
        return nil
    }
    
    static func store(texture: MTLTexture?, name: String) -> Int? {
        guard let texture else { return nil }
        texture.label = name
        if let index = textureIndex[name] {
            return index
        }
        textures.append(texture)
        let index = textures.count - 1
        textureIndex[name] = index
        return index
    }
    
    static func getTexture(_ index: Int?) -> MTLTexture? {
        if let index = index {
            return textures[index]
        }
        return nil
    }
    
    static func loadTexture(texture: MDLTexture, name: String) -> Int? {
        let textureLoader = MTKTextureLoader(device: Renderer.device)
        let textureLoaderOptions: [MTKTextureLoader.Option: Any] =
        [.origin: MTKTextureLoader.Origin.bottomLeft,
         .generateMipmaps: true]
        let texture = try? textureLoader.newTexture(
            texture: texture,
            options: textureLoaderOptions)
        return store(texture: texture, name: name)
    }
    
    static func loadTexture(name: String) -> MTLTexture? {
        let textureLoader = MTKTextureLoader(device: Renderer.device)
        return try? textureLoader.newTexture(
            name: name,
            scaleFactor: 1.0,
            bundle: Bundle.main,
            options: nil)
    }
    
    // load a cube texture
    static func loadCubeTexture(imageName: String) -> MTLTexture? {
        let textureLoader = MTKTextureLoader(device: Renderer.device)
        // asset catalog loading
        if let texture = MDLTexture(cubeWithImagesNamed: [imageName]) {
            let options: [MTKTextureLoader.Option: Any] = [
                .origin: MTKTextureLoader.Origin.topLeft,
                .SRGB: false,
                .generateMipmaps: false
            ]
            return try? textureLoader.newTexture(
                texture: texture,
                options: options)
        }
        // bundle file loading
        let texture = try? textureLoader.newTexture(
            name: imageName,
            scaleFactor: 1.0,
            bundle: .main)
        return texture
    }
    
    static func buildHeap() -> MTLHeap? {
        let heapDescriptor = MTLHeapDescriptor()
        
        let descriptors = textures.map { texture in
            texture.descriptor
        }
        
        let sizeAndAligns = descriptors.map { descriptor in
            Renderer.device.heapTextureSizeAndAlign(descriptor: descriptor)
        }
        heapDescriptor.size = sizeAndAligns.reduce(0) { total, sizeAndAlign in
            let size = sizeAndAlign.size
            let align = sizeAndAlign.align
            return total + size - (size & (align - 1)) + align
        }
        if heapDescriptor.size == 0 {
            return nil
        }
        
        guard let heap =
                Renderer.device.makeHeap(descriptor: heapDescriptor)
        else { return nil }
        
        let heapTextures = descriptors.map { descriptor -> MTLTexture in
            descriptor.storageMode = heapDescriptor.storageMode
            descriptor.cpuCacheMode = heapDescriptor.cpuCacheMode
            guard let texture = heap.makeTexture(descriptor: descriptor) else {
                fatalError("Failed to create heap textures")
            }
            return texture
        }
        
        guard
            let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
            let blitEncoder = commandBuffer.makeBlitCommandEncoder()
        else { return nil }
        zip(textures, heapTextures)
            .forEach { texture, heapTexture in
                heapTexture.label = texture.label
                var region = MTLRegionMake2D(0, 0, texture.width, texture.height)
                for level in 0..<texture.mipmapLevelCount {
                    for slice in 0..<texture.arrayLength {
                        blitEncoder.copy(
                            from: texture,
                            sourceSlice: slice,
                            sourceLevel: level,
                            sourceOrigin: region.origin,
                            sourceSize: region.size,
                            to: heapTexture,
                            destinationSlice: slice,
                            destinationLevel: level,
                            destinationOrigin: region.origin
                        )
                    }
                    region.size.width /= 2
                    region.size.height /= 2
                }
            }
        blitEncoder.endEncoding()
        commandBuffer.commit()
        Self.textures = heapTextures
        
        return heap
    }
}
