import SwiftUI

struct PlayPauseControl: View {
    @ObservedObject var viewModel: MetronomeViewModel
    @State private var isAnimating = false
    
    // Constants for sizing
    private let buttonDiameter: CGFloat = 100
    
    var body: some View {
        ZStack {
            // Simple outer ring
            Circle()
                .stroke(Color(hex: "#8217FF").opacity(0.3), lineWidth: 8)
                .frame(width: buttonDiameter + 40, height: buttonDiameter + 40)
            
            // Tempo text
            VStack {
                Spacer()
                Text("\(Int(viewModel.tempo)) BPM")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, buttonDiameter + 20)
            }
            
            // Play/Pause Button
            Button(action: {
                if viewModel.isPlaying {
                    viewModel.togglePlayback()
                } else {
                    viewModel.togglePlayback()
                }
            }) {
                ZStack {
                    // Button background
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#8217FF"),
                                    Color(hex: "#4F0AA8")
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    // Play/Pause icon
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: buttonDiameter * 0.4))
                        .foregroundColor(.white)
                        .offset(x: viewModel.isPlaying ? 0 : buttonDiameter * 0.05) // Center the play icon visually
                }
            }
            .frame(width: buttonDiameter, height: buttonDiameter)
            .scaleEffect(isAnimating ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAnimating)
        }
        .frame(width: buttonDiameter + 80, height: buttonDiameter + 80)
        .onReceive(viewModel.$currentBeat) { newBeat in
            // Pulse animation on beat 0
            if viewModel.isPlaying && newBeat == 0 {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isAnimating = true
                }
                
                // Reset animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isAnimating = false
                    }
                }
            }
        }
    }
}

// Preview
struct PlayPauseControl_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(hex: "#330D81").edgesIgnoringSafeArea(.all)
            PlayPauseControl(viewModel: MetronomeViewModel())
        }
        .preferredColorScheme(.dark)
    }
} 