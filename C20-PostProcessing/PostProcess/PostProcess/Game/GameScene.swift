import MetalKit

struct GameScene {
    lazy var tree: Model = {
        Model(name: "tree.usdz")
    }()
    
    lazy var window: Model = {
        Model(name: "window.usdz")
    }()
    
    lazy var ground: Model = {
        var ground = Model(name: "ground", primitiveType: .plane)
        ground.setTexture(name: "grass", type: BaseColor)
        ground.scale = 40
        ground.tiling = 8
        ground.rotation.z = Float(270).degreesToRadians
        return ground
    }()
    
    var models: [Model] = []
    var camera = ArcballCamera()
    
    var defaultView = Transform()
    
    var lighting = SceneLighting()
    
    init() {
        tree.position.z = 1.5
        camera.transform = defaultView
        camera.target = tree.position
        camera.target.y = 3
        camera.distance = 5
        camera.far = 20
        window.position = [0, 3, -1]
        models = [window, ground, tree]
    }
    
    mutating func update(size: CGSize) {
        camera.update(size: size)
    }
    
    mutating func update(deltaTime: Float) {
        let input = InputController.shared
        if input.keysPressed.contains(.one) ||
            input.keysPressed.contains(.two) {
            camera.distance = 5
        }
        if input.keysPressed.contains(.one) {
            camera.transform = Transform()
        }
        if input.keysPressed.contains(.two) {
            camera.transform = defaultView
        }
        input.keysPressed.removeAll()
        camera.update(deltaTime: deltaTime)
    }
}
