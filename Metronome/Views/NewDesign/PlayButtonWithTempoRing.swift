import SwiftUI

struct PlayButtonWithTempoRing: View {
    @ObservedObject var viewModel: MetronomeViewModel
    @State private var isAnimating = false
    
    // Constants for sizing
    private let ringDiameter: CGFloat = 280
    private let buttonDiameter: CGFloat = 100
    private let ringWidth: CGFloat = 30
    
    var body: some View {
        ZStack {
            // Tempo Ring (donut shape)
            TempoRing(
                diameter: ringDiameter,
                ringWidth: ringWidth,
                tempo: viewModel.tempo
            )
            
            // Play/Pause Button
            PlayPauseButton(
                isPlaying: viewModel.isPlaying,
                diameter: buttonDiameter,
                onTap: {
                    viewModel.togglePlayback()
                }
            )
            .scaleEffect(isAnimating ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAnimating)
        }
        .frame(width: ringDiameter, height: ringDiameter)
        .onReceive(viewModel.$currentBeat) { newBeat in
            // Pulse animation on each beat when playing
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

// Play/Pause Button Component
struct PlayPauseButton: View {
    let isPlaying: Bool
    let diameter: CGFloat
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Button background - changed to solid light color
                Circle()
                    .fill(Color(hex: "#F3F0DF"))
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                
                // Play/Pause icon - changed color and fixed alignment
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: diameter * 0.4))
                    .foregroundColor(Color(hex: "#8217FF"))
                    // Center both icons properly
                    .offset(x: isPlaying ? 0 : diameter * 0.01) // Reduced offset for better centering
            }
        }
        .frame(width: diameter, height: diameter)
        .buttonStyle(ScaleButtonStyle())
    }
}

// Tempo Ring Component (currently just visual)
struct TempoRing: View {
    let diameter: CGFloat
    let ringWidth: CGFloat
    let tempo: Double
    
    private let gradientColors = [
        Color(hex: "#FF3E9A"),
        Color(hex: "#8217FF"),
        Color(hex: "#4E0DA8")
    ]
    
    var body: some View {
        ZStack {
            // Outer ring background
            Circle()
                .stroke(Color(hex: "#4D6A9A").opacity(0.3), lineWidth: ringWidth)
            
            // Tempo indicator arc
            Circle()
                .trim(from: 0, to: min(tempo / 300.0, 1.0)) // Map tempo to 0-300 BPM range
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: gradientColors),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                )
                .rotationEffect(Angle(degrees: -90)) // Start from top
            
            // Tempo markings
            ForEach(0..<24) { index in
                TempoMark(
                    index: index,
                    count: 24,
                    ringDiameter: diameter,
                    ringWidth: ringWidth
                )
            }
            
            // Tempo text label
            VStack {
                Spacer()
                Text("\(Int(tempo)) BPM")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 30)
            }
        }
        .frame(width: diameter, height: diameter)
    }
}

// Small mark for tempo ring ticks
struct TempoMark: View {
    let index: Int
    let count: Int
    let ringDiameter: CGFloat
    let ringWidth: CGFloat
    
    var body: some View {
        let angle = Double(index) * (360.0 / Double(count))
        let isMainMark = index % 6 == 0
        
        return VStack {
            Rectangle()
                .fill(Color.white.opacity(isMainMark ? 0.8 : 0.4))
                .frame(width: isMainMark ? 3 : 2, height: isMainMark ? 12 : 8)
                .offset(y: -(ringDiameter - ringWidth) / 2 + 2)
            
            if isMainMark {
                Text("\(index * 300 / count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .offset(y: -(ringDiameter - ringWidth) / 2 + 20)
            }
        }
        .rotationEffect(Angle(degrees: angle))
    }
}

// Custom button style for scale effect
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// Preview
struct PlayButtonWithTempoRing_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(hex: "#330D81").edgesIgnoringSafeArea(.all)
            
            PlayButtonWithTempoRing(
                viewModel: {
                    let vm = MetronomeViewModel()
                    vm.tempo = 120
                    return vm
                }()
            )
        }
        .preferredColorScheme(.dark)
    }
} 