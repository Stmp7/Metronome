import SwiftUI
import CoreHaptics

struct BeatIndicatorBar: View {
    let currentBeat: Int
    let totalBeats: Int
    @Binding var accentLevels: [AccentLevel]
    
    // Fixed height
    private let blockHeight: CGFloat = 80
    // Fixed spacing
    private let spacing: CGFloat = 6
    
    // Haptic engine
    @State private var hapticEngine: CHHapticEngine?
    
    var body: some View {
        // Log state just before GeometryReader evaluation
        let _ = print("BeatIndicatorBar body: totalBeats=\(totalBeats), accentLevels.count=\(accentLevels.count), currentBeat=\(currentBeat)")
        
        GeometryReader { geo in
            // Calculate available width for blocks
            let availableWidth = geo.size.width - 48  // 24px left + 24px right margin
            let blockWidth = (availableWidth - (CGFloat(totalBeats - 1) * spacing)) / CGFloat(totalBeats)
            
            // Define the grid layout
            let columns = Array(
                repeating: GridItem(.fixed(blockWidth), spacing: spacing),
                count: totalBeats
            )
            
            // Using a LazyHGrid for perfect spacing
            LazyHGrid(rows: [GridItem(.fixed(blockHeight))], spacing: spacing) {
                ForEach(0..<totalBeats, id: \.self) { index in
                    BeatBlock(
                        index: index,
                        currentBeat: currentBeat,
                        accentLevel: accentLevels.indices.contains(index) ? accentLevels[index] : .piano,
                        width: blockWidth,
                        height: blockHeight,
                        onTap: {
                            if accentLevels.indices.contains(index) {
                                accentLevels[index] = accentLevels[index].next()
                                triggerHapticFeedback()
                            }
                        }
                    )
                }
            }
            .id(totalBeats)
            .animation(nil, value: totalBeats)
            .padding(.horizontal, 24)
        }
        .frame(height: blockHeight + 16)
        .onAppear(perform: prepareHaptics)
    }
    
    // Setup haptic engine
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Haptic engine error: \(error.localizedDescription)")
        }
    }
    
    // Trigger haptic feedback when accent is changed
    private func triggerHapticFeedback() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = hapticEngine else { return }
        
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
        
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play haptic pattern: \(error.localizedDescription)")
        }
    }
}

struct BeatBlock: View {
    let index: Int
    let currentBeat: Int
    let accentLevel: AccentLevel
    let width: CGFloat
    let height: CGFloat
    let onTap: () -> Void
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(accentLevel.color.opacity(accentLevel.fillOpacity))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        currentBeat == index ? Color.white : accentLevel.borderColor,
                        lineWidth: currentBeat == index ? 2 : accentLevel.borderWidth
                    )
            )
            .frame(width: width, height: height)
            .scaleEffect(currentBeat == index ? 1.05 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: currentBeat == index)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    onTap()
                }
            }
    }
}

// Preview provider
struct BeatIndicatorBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            // 4-beat time signature
            BeatIndicatorBar(
                currentBeat: 0,
                totalBeats: 4,
                accentLevels: .constant([.forte, .piano, .piano, .piano])
            )
            .background(Color(hex: "#330D81"))
            
            // 7-beat time signature
            BeatIndicatorBar(
                currentBeat: 2,
                totalBeats: 7,
                accentLevels: .constant([.forte, .piano, .mezzoForte, .piano, .piano, .piano, .piano])
            )
            .background(Color(hex: "#330D81"))
            
            // 3-beat time signature
            BeatIndicatorBar(
                currentBeat: 1,
                totalBeats: 3,
                accentLevels: .constant([.forte, .piano, .piano])
            )
            .background(Color(hex: "#330D81"))
            
            // 12-beat time signature
            BeatIndicatorBar(
                currentBeat: 0,
                totalBeats: 12,
                accentLevels: .constant(
                    [.forte, .piano, .piano, .piano, .mezzoForte, .piano,
                     .piano, .piano, .mezzoForte, .piano, .piano, .piano]
                )
            )
            .background(Color(hex: "#330D81"))
        }
        .padding()
        .background(Color(hex: "#330D81"))
        .preferredColorScheme(.dark)
    }
} 
