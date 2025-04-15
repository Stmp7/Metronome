import SwiftUI

struct BeatIndicator: View {
    let currentBeat: Int
    let totalBeats: Int
    let isPlaying: Bool
    let onPlayStop: () -> Void
    
    private let gap: CGFloat = 8 // Gap between segments in degrees
    
    var body: some View {
        ZStack {
            // Remove the background circle outline that was showing through the gaps
            /*
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 8)
            */
            
            // Dynamic segments based on totalBeats
            ForEach(0..<totalBeats, id: \.self) { index in
                CircleSegment(
                    startAngle: .degrees(Double(index) * (360.0 / Double(totalBeats)) + gap/2),
                    endAngle: .degrees(Double(index + 1) * (360.0 / Double(totalBeats)) - gap/2)
                )
                .stroke(
                    index == currentBeat ? Color(hex: "#8217FF") : Color.gray.opacity(0.3),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round)
                )
            }
            
            // Play/Stop button
            Button(action: onPlayStop) {
                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "#8217FF"))
                    .animation(nil, value: isPlaying) // Disable animation for icon change
            }
        }
        .frame(width: 200, height: 200)
    }
}

// Define the custom ButtonStyle for the bounce effect
struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0) // Scale down when pressed
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed) // Bounce animation
    }
}

// Refactor CircleSegment to be a Shape
struct CircleSegment: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        path.addArc(
            center: center,
            radius: radius, // Use radius based on the provided rect
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct BeatIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Preview for 4/4 time signature
            BeatIndicator(
                currentBeat: 0,
                totalBeats: 4,
                isPlaying: false,
                onPlayStop: {}
            )
            
            // Preview for 3/4 time signature
            BeatIndicator(
                currentBeat: 1,
                totalBeats: 3,
                isPlaying: true,
                onPlayStop: {}
            )
            
            // Preview for 6/8 time signature
            BeatIndicator(
                currentBeat: 2,
                totalBeats: 6,
                isPlaying: false,
                onPlayStop: {}
            )
        }
        .padding()
    }
} 