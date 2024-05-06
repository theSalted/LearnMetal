import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            MetalView()
                .aspectRatio(1, contentMode: .fit)
                .border(Color.black, width: 2)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
