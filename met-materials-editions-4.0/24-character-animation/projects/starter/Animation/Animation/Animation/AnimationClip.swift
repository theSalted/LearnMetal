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

class AnimationClip {
  let name: String
  var jointAnimation: [String: Animation?] = [:]
  var duration: Float = 0
  var speed: Float = 1
  var jointPaths: [String] = []

  init(animation: MDLPackedJointAnimation) {
    self.name = URL(string: animation.name)?.lastPathComponent ?? "Untitled"
    jointPaths = animation.jointPaths
    var duration: Float = 0
    for (jointIndex, jointPath) in animation.jointPaths.enumerated() {
      var jointAnimation = Animation()

      // load rotations
      let rotationTimes = animation.rotations.times
      if let lastTime = rotationTimes.last,
        duration < Float(lastTime) {
        duration = Float(lastTime)
      }
      jointAnimation.rotations =
        rotationTimes.enumerated().map { index, time in
        let startIndex = index * animation.jointPaths.count
        let endIndex = startIndex + animation.jointPaths.count
        let array =
          Array(
            animation.rotations
              .floatQuaternionArray[startIndex..<endIndex])
        return Keyframe(
          time: Float(time),
          value: array[jointIndex])
        }

      // load translations
      let translationTimes = animation.translations.times
      if let lastTime = translationTimes.last,
        duration < Float(lastTime) {
        duration = Float(lastTime)
      }
      jointAnimation.translations =
        translationTimes.enumerated().map { index, time in
        let startIndex = index * animation.jointPaths.count
        let endIndex = startIndex + animation.jointPaths.count

        let array = Array(animation.translations.float3Array[startIndex..<endIndex])
        return Keyframe(
          time: Float(time),
          value: array[jointIndex])
        }
      self.jointAnimation[jointPath] = jointAnimation
    }
    self.duration = duration
  }
}
