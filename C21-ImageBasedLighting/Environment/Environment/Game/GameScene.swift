import CoreGraphics

struct GameScene {
    lazy var ground: Model = {
        var ground = Model(name: "ground", primitiveType: .plane)
        ground.setTexture(name: "grass", type: BaseColor)
        ground.scale = 40
        ground.tiling = 16
        ground.rotation.z = Float(270).degreesToRadians
        return ground
    }()
    lazy var car: Model = {
        Model(name: "racing-car.usdz")
    }()
    
    var models: [Model] = []
    var camera = ArcballCamera()
    var defaultView: Transform {
        Transform(
            position: [3.65, 1.89, 1.23],
            rotation: [-0.28, -1.9, 0])
    }
    var lighting = SceneLighting()
    let skybox: Skybox?
    
    init() {
        skybox = Skybox(textureName: "sky")
        camera.transform = defaultView
        camera.target = car.position
        camera.target.y += 0.8
        camera.distance = 4
        camera.far = 15
        models = [ground, car]
    }
    
    mutating func update(size: CGSize) {
        camera.update(size: size)
    }
    
    mutating func update(deltaTime: Float) {
        let input = InputController.shared
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
