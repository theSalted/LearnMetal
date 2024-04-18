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
        var ground = Model(
            name: "ground",
            primitiveType: .plane)
        ground.scale = 40
        ground.rotation.z = Float(270).degreesToRadians
        ground.meshes[0].submeshes[0].material.baseColor = [0.9, 0.9, 0.9]
        return ground
    }()
    
    var models: [Model] = []
    var camera = ArcballCamera()
    
    var defaultView: Transform {
        Transform(
            position: [3.2, 3.1, 1.0],
            rotation: [-0.6, 10.7, 0.0])
    }
    
    var lighting = SceneLighting()
    
    init() {
        camera.far = 10
        camera.transform = defaultView
        camera.target = [0, 1, 0]
        camera.distance = 4
        treefir1.position = [-1, 0, 2.5]
        treefir2.position = [-3, 0, -2]
        treefir3.position = [1.5, 0, -0.5]
        models = [ground, treefir1, treefir2, treefir3, train]
    }
    
    mutating func update(size: CGSize) {
        camera.update(size: size)
    }
    
    mutating func update(deltaTime: Float) {
        updateInput()
        camera.update(deltaTime: deltaTime)
    }
    
    mutating func updateInput() {
        let input = InputController.shared
        if input.keysPressed.contains(.one) ||
            input.keysPressed.contains(.two) {
            camera.distance = 4
        }
        if input.keysPressed.contains(.one) {
            camera.transform = Transform()
        }
        if input.keysPressed.contains(.two) {
            camera.transform = defaultView
        }
        input.keysPressed.removeAll()
    }
}
