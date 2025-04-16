import SwiftUI
import CoreHaptics

struct MinimalMetronomeView: View {
    @State private var showingTimeSignaturePicker = false
    @State private var beatsPerMeasure: Int = 4
    @State private var noteValue: Int = 4
    @State private var accentPattern: [AccentLevel] = [.forte, .piano, .piano, .piano]
    @State private var currentBeat: Int = 0
    @State private var isPlaying: Bool = false
    @State private var timer: Timer? = nil
    @State private var initialDelayTimer: Timer? = nil
    @State private var isFirstTick: Bool = true
    @Binding var currentDesign: Design
    
    // Draft state for time signature picker
    @State private var draftBeatsPerMeasure: Int = 4
    @State private var draftNoteValue: Int = 4
    
    // Tempo state and keypad
    @State private var tempo: Double = 120.0
    @State private var showingTempoKeypad = false
    
    // Fixed tempo for demo (120 BPM)
    private var interval: Double { 60.0 / tempo }
    private let soundService = MinimalMetronomeSoundService()
    
    @State private var engine: CHHapticEngine? = nil
    
    var body: some View {
        ZStack {
            Color(hex: "#330D81").ignoresSafeArea()
            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    Button(action: {
                        // Copy real state to draft state when opening picker
                        draftBeatsPerMeasure = beatsPerMeasure
                        draftNoteValue = noteValue
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
                // Tempo Display
                VStack(spacing: 4) {
                    Button(action: { showingTempoKeypad = true }) {
                        VStack(spacing: 0) {
                            Text("\(Int(tempo))")
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .contentShape(Rectangle())
                            Text("BPM")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.75))
                                .padding(.top, 2)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top, 10)
                // Tempo Dial + Play Button
                ZStack {
                    TempoDial(
                        bpm: $tempo,
                        minBPM: 40,
                        maxBPM: 240,
                        diameter: 220,
                        innerDiameter: 96,
                        tickInterval: 5,
                        color: Color(hex: "#200854"),
                        tickColor: Color.white.opacity(0.25),
                        onHaptic: { performHaptic() }
                    )
                    MinimalPlayPauseButton(isPlaying: $isPlaying)
                        .frame(width: 88, height: 88)
                }
                .frame(height: 220)
                .padding(.bottom, 32)
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
                isFirstTick = false
                startInitialDelay()
            } else {
                stopMetronome()
            }
        }
        .onChange(of: accentPattern.count) { _ in
            // Reset beat if pattern changes
            currentBeat = 0
        }
        .sheet(isPresented: $showingTimeSignaturePicker, onDismiss: {
            // Do nothing on dismiss; real state remains unchanged
        }) {
            VStack(spacing: 16) {
                TimeSignaturePicker(
                    beatsPerMeasure: $draftBeatsPerMeasure,
                    noteValue: $draftNoteValue
                )
                .padding(.horizontal)
                .padding(.top, 20)
                HStack(spacing: 16) {
                    Button("Cancel") {
                        showingTimeSignaturePicker = false
                    }
                    .buttonStyle(SecondaryDrawerButtonStyle())
                    Button("Apply") {
                        // Generate new accent pattern, preserving user selections
                        let oldPattern = accentPattern
                        var newPattern = Array(repeating: AccentLevel.piano, count: draftBeatsPerMeasure)
                        if !newPattern.isEmpty {
                            newPattern[0] = .forte
                        }
                        for i in 0..<min(oldPattern.count, draftBeatsPerMeasure) {
                            newPattern[i] = oldPattern[i]
                        }
                        beatsPerMeasure = draftBeatsPerMeasure
                        noteValue = draftNoteValue
                        accentPattern = newPattern
                        showingTimeSignaturePicker = false
                    }
                    .buttonStyle(PrimaryDrawerButtonStyle())
                }
                .padding(.bottom, 16)
            }
            .presentationDetents([.height(350)])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color(hex: "#330D81"))
        }
        .sheet(isPresented: $showingTempoKeypad) {
            let maxHeight = min(550, UIScreen.main.bounds.height * 0.8)
            ZStack {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                VStack {
                    Spacer(minLength: 0)
                    TempoKeypad(
                        tempo: $tempo,
                        onCancel: { showingTempoKeypad = false },
                        onDone: { showingTempoKeypad = false }
                    )
                    .background(Color(hex: "#330D81"))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                }
            }
            .presentationDetents([.height(maxHeight)])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color(hex: "#330D81"))
        }
        .onAppear { prepareHaptics() }
    }
    
    private func startInitialDelay() {
        stopMetronome()
        initialDelayTimer?.invalidate()
        initialDelayTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
            DispatchQueue.main.async {
                let accent = accentPattern[currentBeat]
                soundService.playAccent(accent)
                startMetronome()
            }
        }
    }
    
    private func startMetronome() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            DispatchQueue.main.async {
                currentBeat = (currentBeat + 1) % accentPattern.count
                let accent = accentPattern[currentBeat]
                soundService.playAccent(accent)
            }
        }
    }
    
    private func stopMetronome() {
        timer?.invalidate()
        timer = nil
        initialDelayTimer?.invalidate()
        initialDelayTimer = nil
    }
    
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch { engine = nil }
    }
    
    private func performHaptic() {
        guard let engine = engine else { return }
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [sharpness, intensity], relativeTime: 0)
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {}
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
                    .fill(Color(hex: "#F3F0DF"))
                    .frame(width: 90, height: 90)
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(Color(hex: "#8217FF"))
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

// Add custom button styles for drawer buttons
struct PrimaryDrawerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(Color(hex: "#8217FF"))
            .frame(minWidth: 120)
            .padding(.vertical, 10)
            .background(Color(hex: "#F3F0DF"))
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct SecondaryDrawerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(Color(hex: "#F3F0DF"))
            .frame(minWidth: 120)
            .padding(.vertical, 10)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "#F3F0DF"), lineWidth: 2)
            )
            .background(Color.clear)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct TempoDial: View {
    @Binding var bpm: Double
    let minBPM: Double
    let maxBPM: Double
    let diameter: CGFloat
    let innerDiameter: CGFloat
    let tickInterval: Int
    let color: Color
    let tickColor: Color
    let onHaptic: () -> Void
    @State private var lastAngle: CGFloat? = nil
    @State private var lastBPM: Int = 0
    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
            let borderWidth: CGFloat = 14
            let borderDiameter = diameter - borderWidth
            let tickLength: CGFloat = 8
            let tickCount = Int((maxBPM-minBPM)/Double(tickInterval/2))+1
            ZStack {
                // Donut base
                Circle()
                    .fill(color)
                    .frame(width: diameter, height: diameter)
                // Outer border (inset)
                Circle()
                    .stroke(Color(hex: "#110034"), lineWidth: borderWidth)
                    .frame(width: borderDiameter, height: borderDiameter)
                // Donut hole
                Circle()
                    .fill(Color.clear)
                    .frame(width: innerDiameter, height: innerDiameter)
                    .blendMode(.destinationOut)
                // Tick marks (centered on border)
                ForEach(0..<tickCount, id: \ .self) { i in
                    let angle = Angle(degrees: Double(i) / Double(tickCount) * 360)
                    Capsule()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 1, height: 8)
                        .offset(y: -(borderDiameter/2))
                        .rotationEffect(angle, anchor: .center)
                }
            }
            .compositingGroup()
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let dragPoint = value.location
                    let dx = dragPoint.x - center.x
                    let dy = dragPoint.y - center.y
                    let distance = sqrt(dx*dx + dy*dy)
                    // Only allow dragging on the ring
                    if distance < innerDiameter/2 + 12 || distance > diameter/2 - 12 { return }
                    let angle = atan2(dy, dx)
                    let degrees = angle * 180 / .pi
                    let normalized = (degrees + 360).truncatingRemainder(dividingBy: 360)
                    let sweep = min(max(normalized, 0), 360)
                    let newBPM = Int(round(Double(minBPM) + (Double(sweep)/360) * (maxBPM-minBPM)))
                    if newBPM != Int(bpm) {
                        bpm = Double(newBPM)
                        onHaptic()
                    }
                }
            )
        }
        .frame(width: diameter, height: diameter)
    }
} 