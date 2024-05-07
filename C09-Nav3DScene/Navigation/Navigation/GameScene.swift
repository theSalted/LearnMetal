import Foundation

struct GameScene {
    lazy var house: Model = {
        let house = Model(name: "lowpoly-house.usdz")
        house.setTexture(name: "barn-color", type: BaseColor)
        return house
    }()
    
    lazy var ground: Model = {
        let ground = Model(name: "ground", primitiveType: .plane)
        ground.setTexture(name: "barn-ground", type: BaseColor)
        ground.tiling = 16
        ground.transform.scale = 40
        ground.transform.rotation.z = Float(90).degreesToRadians
        return ground
    }()
    
    lazy var models: [Model] = [ground, house]
    var camera = PlayerCamera()
    
    init() {
        camera.position = [0, 1.4, -4.0]
        
    }
    
    mutating func update(deltaTime: Float) {
        camera.update(deltaTime: deltaTime)
        
        if InputController.shared.keysPressed.contains(.keyH) {
            print("H key pressed")
        }
    }
    
    mutating func update(size: CGSize) {
        camera.update(size: size)
    }
}

