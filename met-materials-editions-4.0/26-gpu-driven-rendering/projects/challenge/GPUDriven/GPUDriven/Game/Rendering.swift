///// Copyright (c) 2023 Kodeco Inc.
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import MetalKit

// Rendering
extension Model {
  func render(encoder: MTLRenderCommandEncoder) {
    encoder.pushDebugGroup(name)
    if let pipelineState {
      encoder.setRenderPipelineState(pipelineState)
    }

    // make the structures mutable
    modelParams.tiling = tiling

    for mesh in meshes {

      setVertexBuffers(encoder: encoder, mesh: mesh)

      for submesh in mesh.submeshes {
        encoder.setFragmentBytes(
          &modelParams,
          length: MemoryLayout<ModelParams>.stride,
          index: ModelParamsBuffer.index)

        encoder.setFragmentBuffer(
          submesh.materialsBuffer,
          offset: 0,
          index: MaterialBuffer.index)
        encoder.drawIndexedPrimitives(
          type: .triangle,
          indexCount: submesh.indexCount,
          indexType: submesh.indexType,
          indexBuffer: submesh.indexBuffer,
          indexBufferOffset: submesh.indexBufferOffset
        )
      }
    }
    encoder.popDebugGroup()
  }

  func setVertexBuffers(
    encoder: MTLRenderCommandEncoder,
    mesh: Mesh) {
    if let paletteBuffer = mesh.skin?.jointMatrixPaletteBuffer {
      encoder.setVertexBuffer(
        paletteBuffer,
        offset: 0,
        index: JointMatrixBuffer.index)
    }
    let currentLocalTransform =
      mesh.transform?.currentTransform ?? .identity
    modelParams.modelMatrix =
      transform.modelMatrix * currentLocalTransform
    modelParams.normalMatrix = modelParams.modelMatrix.upperLeft
    encoder.setVertexBytes(
      &modelParams,
      length: MemoryLayout<ModelParams>.stride,
      index: ModelParamsBuffer.index)

    for (index, vertexBuffer) in mesh.vertexBuffers.enumerated() {
      encoder.setVertexBuffer(
        vertexBuffer,
        offset: 0,
        index: index)
    }
  }

  func updateFragmentMaterials(
    encoder: MTLRenderCommandEncoder,
    submesh: Submesh
  ) {
    for (index, texture) in submesh.allTextures.enumerated() {
      encoder.setFragmentTexture(texture, index: index)
    }
    var material = submesh.material
    encoder.setFragmentBytes(
      &material,
      length: MemoryLayout<Material>.stride,
      index: MaterialBuffer.index)
  }
}
