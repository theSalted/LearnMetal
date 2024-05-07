import MetalPerformanceShaders

let device = MTLCreateSystemDefaultDevice()!
let commandQueue = device.makeCommandQueue()!

let size = 4
let count = size * size

func createMPSMatrix(withRepeatingValue: Float) -> MPSMatrix {
    let rowBytes = MPSMatrixDescriptor.rowBytes(forColumns: size, dataType: .float32)
    let array = [Float](repeating: withRepeatingValue, count: count)
    let buffer = device.makeBuffer(bytes: array, length: size * rowBytes, options: [])!
    
    let matrixDescriptor = MPSMatrixDescriptor(
        rows: size,
        columns: size,
        rowBytes: rowBytes,
        dataType: .float32)
    
    return MPSMatrix(buffer: buffer, descriptor: matrixDescriptor)
}

let A = createMPSMatrix(withRepeatingValue: 2000)
let B = createMPSMatrix(withRepeatingValue: 2)
let C = createMPSMatrix(withRepeatingValue: 1)

let multiplicationKernel = MPSMatrixMultiplication(
    device: device,
    transposeLeft: false,
    transposeRight: false,
    resultRows: size,
    resultColumns: size,
    interiorColumns: size,
    alpha: 1.0,
    beta: 0.0
)

let commandBuffer = commandQueue.makeCommandBuffer()!

multiplicationKernel.encode(
    commandBuffer: commandBuffer,
    leftMatrix: A,
    rightMatrix: B,
    resultMatrix: C)

commandBuffer.commit()
commandBuffer.waitUntilCompleted()




let contents = C.data.contents()
let pointer = contents.bindMemory(to: Float.self, capacity: count)

(0..<count).map {
    pointer.advanced(by: $0).pointee
}




