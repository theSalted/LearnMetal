import MetalKit

struct GameScene {
    lazy var train: Model = {
        Model(name: "train.usdz")
    }()
    lazy var treefir1: Model = {
        Model(name: "treefir.usdz")
    }()
    lazy var treefir2: Model = {
        Model(name: "treefir.usdz")
    }()
    lazy var treefir3: Model = {
        Model(name: "treefir.usdz")
    }()
    
    lazy var ground: Model = {
        var ground = Model(name: "ground", primitiveType: .plane)
        ground.scale = 40
        ground.rotation.z = Float(270).degreesToRadians
        ground.meshes[0].submeshes[0].material.baseColor = [0.9, 0.9, 0.9]
        return ground
    }()
    
    lazy var sun: Model = {
        var sun = Model(name: "sun", primitiveType: .sphere)
        sun.scale = 0.2
        sun.rotation.z = Float(270).degreesToRadians
        sun.meshes[0].submeshes[0].material.baseColor = [0.9, 0.9, 0.9]
        return sun
    }()
    
    var models: [Model] = []
    var camera = ArcballCamera()
    
    var defaultView: Transform {
        Transform(
            position: [3.2, 3.1, 1.0],
            rotation: [-0.6, 10.7, 0.0])
    }
    
    var lighting = SceneLighting()
    
    var debugMainCamera: ArcballCamera?
    var debugShadowCamera: OrthographicCamera?
    
    var shouldDrawMainCamera = false
    var shouldDrawLightCamera = false
    var shouldDrawBoundingSphere = false
    
    var isPaused = false
    
    init() {
        camera.transform = defaultView
        camera.target = [0, 1, 0]
        camera.far = 10
        camera.distance = 4
        treefir1.position = [-1, 0, 2.5]
        treefir2.position = [-3, 0, -2]
        treefir3.position = [1.5, 0, -0.5]
        models = [treefir1, treefir2, treefir3, train, ground]
    }
    
    mutating func update(size: CGSize) {
        camera.update(size: size)
    }
    
    mutating func update(deltaTime: Float) {
        updateInput()
        camera.update(deltaTime: deltaTime)
        if isPaused { return }
        // rotate light around scene
        let rotationMatrix = float4x4(rotation: [0, deltaTime * 0.4, 0])
        let position = lighting.lights[0].position
        lighting.lights[0].position =
        (rotationMatrix * float4(position.x, position.y, position.z, 1)).xyz
        sun.position = lighting.lights[0].position
    }
    
    mutating func updateInput() {
        let input = InputController.shared
        if input.keysPressed.contains(.one) ||
            input.keysPressed.contains(.two) {
            camera.distance = 4
            if let mainCamera = debugMainCamera {
                camera = mainCamera
                debugMainCamera = nil
                debugShadowCamera = nil
            }
            shouldDrawMainCamera = false
            shouldDrawLightCamera = false
            shouldDrawBoundingSphere = false
            isPaused = false
        }
        if input.keysPressed.contains(.one) {
            camera.transform = Transform()
        }
        if input.keysPressed.contains(.two) {
            camera.transform = defaultView
        }
        if input.keysPressed.contains(.three) {
            shouldDrawMainCamera.toggle()
        }
        if input.keysPressed.contains(.four) {
            shouldDrawLightCamera.toggle()
        }
        if input.keysPressed.contains(.five) {
            shouldDrawBoundingSphere.toggle()
        }
        if !isPaused {
            if shouldDrawMainCamera || shouldDrawLightCamera || shouldDrawBoundingSphere {
                isPaused = true
                debugMainCamera = camera
                debugShadowCamera = OrthographicCamera()
                debugShadowCamera?.viewSize = 16
                debugShadowCamera?.far = 16
                let sun = lighting.lights[0]
                debugShadowCamera?.position = sun.position
                camera.distance = 40
                camera.far = 50
                camera.fov = 120
            }
        }
        input.keysPressed.removeAll()
    }
}
