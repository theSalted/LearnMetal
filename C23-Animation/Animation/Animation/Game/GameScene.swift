import MetalKit

struct GameScene {
    lazy var ball: Model = {
        Model(name: "beachball.usdz")
    }()
    lazy var ground: Model = {
        var model = Model(name: "ground", primitiveType: .plane)
        model.setTexture(name: "grass", type: BaseColor)
        model.scale = 40
        model.tiling = 20
        model.rotation.z = Float(270).degreesToRadians
        return model
    }()
    lazy var beachball = Beachball(model: ball)
    
    var models: [Model] = []
    var camera = PlayerCamera()
    var defaultView: Transform {
        Transform(
            position: [0, 1, -3],
            rotation: [0, 0, 0])
    }
    var lighting = SceneLighting()
    
    init() {
        camera.transform = defaultView
        camera.far = 20
        models = [ball, ground]
    }
    
    mutating func update(size: CGSize) {
        camera.update(size: size)
    }
    
    mutating func update(deltaTime: Float) {
        for model in models {
            model.update(deltaTime: deltaTime)
        }
        
        let input = InputController.shared
        if input.keysPressed.contains(.one) {
            camera.transform = Transform()
            input.keysPressed.remove(.one)
        }
        if input.keysPressed.contains(.two) {
            camera.transform = defaultView
            input.keysPressed.remove(.two)
        }
        let positionYDelta = (input.mouseScroll.x + input.mouseScroll.y)
        * Settings.mouseScrollSensitivity
        let minY: Float = -1
        if camera.position.y + positionYDelta > minY {
            camera.position.y += positionYDelta
        }
        input.mouseScroll = .zero
        
        camera.update(deltaTime: deltaTime)
    }
}
