import SwiftUI

struct MinimalMetronomeView: View {
    @State private var showingTimeSignaturePicker = false
    @State private var beatsPerMeasure: Int = 4
    @State private var noteValue: Int = 4
    @State private var accentPattern: [AccentLevel] = [.forte, .piano, .piano, .piano]
    @State private var currentBeat: Int = 0
    @State private var isPlaying: Bool = false
    @State private var timer: Timer? = nil
    @Binding var currentDesign: Design
    
    // Fixed tempo for demo (120 BPM)
    private let tempo: Double = 120.0
    private var interval: Double { 60.0 / tempo }
    private let soundService = MinimalMetronomeSoundService()
    
    var body: some View {
        ZStack {
            Color(hex: "#330D81").ignoresSafeArea()
            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    Button(action: {
                        showingTimeSignaturePicker = true
                    }) {
                        Text("\(beatsPerMeasure)/\(noteValue)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.2))
                            )
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 20)
                BeatIndicatorBar(
                    currentBeat: currentBeat,
                    totalBeats: accentPattern.count,
                    accentLevels: $accentPattern
                )
                .padding(.top, 10)
                // Play/Pause Button
                MinimalPlayPauseButton(isPlaying: $isPlaying)
                    .padding(.top, 24)
                Button("Switch to Classic Design") {
                    currentDesign = .classic
                }
                .padding()
                .buttonStyle(.bordered)
                .tint(.white)
                .padding(.bottom, 20)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            if showingTimeSignaturePicker {
                Color.black.opacity(0.5).ignoresSafeArea()
            }
        }
        .onChange(of: isPlaying) { playing in
            if playing {
                currentBeat = 0 // Always start from the first beat when playing starts
                startMetronome()
            } else {
                stopMetronome()
            }
        }
        .onChange(of: accentPattern.count) { _ in
            // Reset beat if pattern changes
            currentBeat = 0
        }
        .sheet(isPresented: $showingTimeSignaturePicker) {
            VStack(spacing: 16) {
                TimeSignaturePicker(
                    beatsPerMeasure: $beatsPerMeasure,
                    noteValue: $noteValue
                )
                .padding(.horizontal)
                .padding(.top, 20)
                HStack(spacing: 16) {
                    Button("Cancel") {
                        showingTimeSignaturePicker = false
                    }
                    .padding()
                    .frame(minWidth: 100)
                    .buttonStyle(.bordered)
                    .tint(Color.white.opacity(0.8))
                    Button("Apply") {
                        // Generate new accent pattern, preserving user selections
                        let oldPattern = accentPattern
                        var newPattern = Array(repeating: AccentLevel.piano, count: beatsPerMeasure)
                        if !newPattern.isEmpty {
                            newPattern[0] = .forte
                        }
                        for i in 0..<min(oldPattern.count, beatsPerMeasure) {
                            newPattern[i] = oldPattern[i]
                        }
                        accentPattern = newPattern
                        showingTimeSignaturePicker = false
                    }
                    .padding()
                    .frame(minWidth: 100)
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "#8217FF"))
                    .font(.headline)
                }
                .padding(.bottom, 16)
            }
            .presentationDetents([.height(350)])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color(hex: "#330D81"))
        }
    }
    
    private func startMetronome() {
        stopMetronome()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            let accent = accentPattern[currentBeat]
            soundService.playAccent(accent)
            currentBeat = (currentBeat + 1) % accentPattern.count
        }
    }
    
    private func stopMetronome() {
        timer?.invalidate()
        timer = nil
    }
}

struct MinimalPlayPauseButton: View {
    @Binding var isPlaying: Bool
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isPlaying.toggle()
            }
        }) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "#8217FF"), Color(hex: "#4E0DA8")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                    .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(isPlaying ? "Pause" : "Play")
    }
}

// Replace the main view with this for diagnosis
struct NewMetronomeView: View {
    @Binding var currentDesign: Design
    var body: some View {
        MinimalMetronomeView(currentDesign: $currentDesign)
    }
}

struct NewMetronomeView_Previews: PreviewProvider {
    @State static var previewDesign: Design = .new
    static var previews: some View {
        NewMetronomeView(currentDesign: $previewDesign)
    }
} 