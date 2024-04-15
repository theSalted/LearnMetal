import MetalKit
// swiftlint:disable force_unwrapping
// swiftlint:disable identifier_name

struct SceneLighting {
  static func buildDefaultLight() -> Light {
    var light = Light()
    light.position = [0, 0, 0]
    light.color = float3(repeating: 1.0)
    light.specularColor = float3(repeating: 0.6)
    light.attenuation = [1, 0, 0]
    light.type = Sun
    return light
  }

  let sunlight: Light = {
    var light = Self.buildDefaultLight()
    light.position = [3, 3, -2]
    light.color = float3(repeating: 1)
    return light
  }()

  var lights: [Light]
  var sunLights: [Light]
  var pointLights: [Light]
  var lightsBuffer: MTLBuffer
  var sunBuffer: MTLBuffer
  var pointBuffer: MTLBuffer

  init() {
    sunLights = [sunlight]
    pointLights = Self.createPointLights(
      count: 20,
      min: [-3, 0.1, -3],
      max: [3, 0.3, 3])
    lights = sunLights + pointLights
    lightsBuffer = Self.createBuffer(lights: lights)
    sunBuffer = Self.createBuffer(lights: sunLights)
    pointBuffer = Self.createBuffer(lights: pointLights)
  }

  static func createBuffer(lights: [Light]) -> MTLBuffer {
    var lights = lights
    return Renderer.device.makeBuffer(
      bytes: &lights,
      length: MemoryLayout<Light>.stride * lights.count,
      options: [])!
  }

  static func createPointLights(count: Int, min: float3, max: float3) -> [Light] {
    let colors: [float3] = [
      float3(1, 0, 0),
      float3(1, 1, 0),
      float3(1, 1, 1),
      float3(0, 1, 0),
      float3(0, 1, 1),
      float3(0, 0, 1),
      float3(0, 1, 1),
      float3(1, 0, 1)
    ]
    var lights: [Light] = []
    for _ in 0..<count {
      var light = Self.buildDefaultLight()
      light.type = Point
      let x = Float.random(in: min.x...max.x)
      let y = Float.random(in: min.y...max.y)
      let z = Float.random(in: min.z...max.z)
      light.position = [x, y, z]
      light.color = colors[Int.random(in: 0..<colors.count)]
      light.attenuation = [0.2, 10, 50]
      lights.append(light)
    }
    return lights
  }

  static func createOnePointLight() -> [Light] {
    var pointLights = Self.createPointLights(count: 1, min: [0, 0.6, -0.4], max: [0, 0.6, -0.4])
    pointLights[0].color = [1, 0, 0]
    pointLights[0].attenuation = [1, 4, 10]
    return pointLights
  }
}
// swiftlint:enable identifier_name
// swiftlint:enable force_unwrapping
