import MetalKit

struct GameScene {
    lazy var cottage: Model = {
        Model(name: "house.usdz")
    }()
    
    var models: [Model] = []
    var camera = PlayerCamera()
    var defaultView: Transform {
        Transform(
            position: [1.32, 2.96, 35.38],
            rotation: [-0.16, 3.09, 0])
    }
    var lighting = SceneLighting()
    let skybox: Skybox?
    var water: Water?
    var terrain: Terrain?
    
    init() {
        skybox = Skybox(textureName: "sky")
        terrain = Terrain(name: "terrain.usdz")
        terrain?.tiling = 30
        terrain?.position.y = 3
        
        camera.transform = defaultView
        camera.far = 50
        
        cottage.position = [0, 0.4, 10]
        cottage.rotation.y = 0.2
        models = [cottage]
        water = Water()
        water?.position = [0, -1, 0]
    }
    
    mutating func update(size: CGSize) {
        camera.update(size: size)
    }
    
    mutating func update(deltaTime: Float) {
        water?.update(deltaTime: deltaTime)
        
        let input = InputController.shared
        if input.keysPressed.contains(.one) {
            camera.transform = Transform()
            camera.transform.rotation.x = -.pi / 2
            camera.transform.position = [4, 30, 22]
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
