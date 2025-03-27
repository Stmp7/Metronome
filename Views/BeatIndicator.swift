import SwiftUI

struct BeatIndicator: View {
    let currentBeat: Int
    let totalBeats: Int
    let isPlaying: Bool
    
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Circle()
            .fill(currentBeat == 0 ? Color.blue : Color.gray)
            .frame(width: 200, height: 200)
            .scaleEffect(scale)
            .animation(.easeInOut(duration: 0.1), value: scale)
            .onChange(of: currentBeat) { _ in
                if isPlaying {
                    scale = 1.2
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        scale = 1.0
                    }
                }
            }
    }
} 