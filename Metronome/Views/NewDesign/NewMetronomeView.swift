import SwiftUI
import CoreHaptics
import AVFoundation

struct MinimalMetronomeView: View {
    @ObservedObject var viewModel: NewMetronomeViewModel
    @Binding var currentDesign: Design
    @State private var showingTimeSignaturePicker = false
    @State private var draftBeatsPerMeasure: Int = 4
    @State private var draftNoteValue: Int = 4
    @State private var showingTempoKeypad = false
    private let soundService = MinimalMetronomeSoundService()
    @State private var engine: CHHapticEngine? = nil
    @State private var lastAngle: CGFloat? = nil
    @State private var lastBPM: Int = 0
    @State private var dialAngle: Double = 0 // in degrees
    @State private var isDragging: Bool = false
    private var interval: Double { 60.0 / viewModel.tempo }
    @State private var beatProgress: Double = 0.0 // 0...1
    @State private var displayLink: CADisplayLink? = nil
    
    var body: some View {
        ZStack {
            Color(hex: "#330D81").ignoresSafeArea()
            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    let denominator = Int(viewModel.timeSignature.rawValue.split(separator: "/").last ?? "4") ?? 4
                    Button(action: {
                        draftBeatsPerMeasure = viewModel.accentPattern.count
                        draftNoteValue = denominator
                        showingTimeSignaturePicker = true
                    }) {
                        Text("\(viewModel.accentPattern.count)/\(denominator)")
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
                    currentBeat: viewModel.currentBeat,
                    totalBeats: viewModel.accentPattern.count,
                    accentLevels: $viewModel.accentPattern
                )
                .padding(.top, 10)
                // Tempo Display
                VStack(spacing: 4) {
                    Button(action: { showingTempoKeypad = true }) {
                        VStack(spacing: 0) {
                            Text("\(Int(viewModel.tempo))")
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
                        bpm: $viewModel.tempo,
                        minBPM: 40,
                        maxBPM: 240,
                        diameter: 220,
                        innerDiameter: 96,
                        tickInterval: 5,
                        color: Color(hex: "#200854"),
                        tickColor: Color.white.opacity(0.25),
                        onHaptic: { performHaptic() },
                        onTick: { /* no-op, sound is handled by ViewModel */ },
                        beatProgress: beatProgress
                    )
                    MinimalPlayPauseButton(
                        onToggle: { viewModel.togglePlayback() },
                        isPlaying: viewModel.isPlaying
                    )
                    .frame(width: 88, height: 88)
                }
                .frame(width: 220, height: 220)
                .padding(.bottom, 32)

                // Tap Tempo button to the right above Switch button
                HStack {
                    Spacer()
                    TapTempoButton(onTap: { viewModel.handleTapTempo() })
                        .frame(width: 64, height: 64)
                        .padding(.trailing, 24)
                        .padding(.bottom, 8)
                }

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
        .sheet(isPresented: $showingTimeSignaturePicker, onDismiss: {}) {
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
                        let denominator = Int(viewModel.timeSignature.rawValue.split(separator: "/").last ?? "4") ?? 4
                        let oldPattern = viewModel.accentPattern
                        var newPattern = Array(repeating: AccentLevel.piano, count: draftBeatsPerMeasure)
                        if !newPattern.isEmpty { newPattern[0] = .forte }
                        for i in 0..<min(oldPattern.count, draftBeatsPerMeasure) {
                            newPattern[i] = oldPattern[i]
                        }
                        let newTS = TimeSignature(rawValue: "\(draftBeatsPerMeasure)/\(denominator)") ?? .fourFour
                        viewModel.setTimeSignature(newTS)
                        viewModel.accentPattern = newPattern
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
                        tempo: $viewModel.tempo,
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
        .onAppear {
            prepareHaptics()
            startDisplayLink()
        }
        .onDisappear {
            stopDisplayLink()
        }
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
    
    // --- CADisplayLink logic ---
    private func startDisplayLink() {
        stopDisplayLink()
        let link = CADisplayLink(target: DisplayLinkProxy(target: self), selector: #selector(DisplayLinkProxy.tick))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }
    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    private func updateBeatProgress() {
        guard viewModel.isPlaying, let nextBeatTime = viewModel.nextBeatTime else {
            beatProgress = 0.0
            return
        }
        let now = AVAudioTime.hostTime(forSeconds: CACurrentMediaTime())
        let nowTime = AVAudioTime(hostTime: now)
        if nextBeatTime.isHostTimeValid && nowTime.isHostTimeValid {
            let nextBeatSeconds = AVAudioTime.seconds(forHostTime: nextBeatTime.hostTime)
            let nowSeconds = AVAudioTime.seconds(forHostTime: nowTime.hostTime)
            let secondsUntilNext = nextBeatSeconds - nowSeconds
            let interval = 60.0 / viewModel.tempo
            let progress = 1.0 - min(max(secondsUntilNext / interval, 0.0), 1.0)
            beatProgress = progress
        } else {
            beatProgress = 0.0
        }
    }
    // Proxy to allow CADisplayLink to call a SwiftUI view method
    private class DisplayLinkProxy {
        private let target: MinimalMetronomeView
        init(target: MinimalMetronomeView) { self.target = target }
        @objc func tick() { target.updateBeatProgress() }
    }
    // --- End CADisplayLink logic ---
}

struct MinimalPlayPauseButton: View {
    var onToggle: () -> Void
    var isPlaying: Bool
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                onToggle()
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

struct NewMetronomeView: View {
    @Binding var currentDesign: Design
    @StateObject private var viewModel = NewMetronomeViewModel()
    var body: some View {
        MinimalMetronomeView(viewModel: viewModel, currentDesign: $currentDesign)
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
    let onTick: () -> Void
    let beatProgress: Double
    @State private var lastAngle: CGFloat? = nil
    @State private var lastBPM: Int = 0
    @State private var dialAngle: Double = 0 // in degrees
    @State private var isDragging: Bool = false

    private var borderWidth: CGFloat { 14 }
    private var borderDiameter: CGFloat { diameter - borderWidth }
    private var tickCount: Int { Int((maxBPM-minBPM)/Double(tickInterval/2))+1 }
    private var dotRadius: CGFloat { 9 }
    private var dotOffset: CGFloat { (diameter / 2) - borderWidth - dotRadius - 6 }
    private var bpmRange: Double { maxBPM - minBPM }
    private var anglePerBPM: Double { 360.0 / bpmRange }
    private var indicatorAngle: Angle {
        let progress = (bpm - minBPM) / (maxBPM - minBPM)
        return Angle(degrees: 180 + (progress * 360))
    }
    private var innerShadow: ShadowStyle { .inner(color: .black.opacity(0.5), radius: 4, x: 0, y: -8) }

    private var tickMarks: some View {
        ForEach(0..<tickCount, id: \ .self) { i in
            let angle = Angle(degrees: Double(i) / Double(tickCount) * 360)
            Capsule()
                .fill(Color.white.opacity(0.25))
                .frame(width: 1, height: 8)
                .offset(y: -(borderDiameter/2))
                .rotationEffect(angle, anchor: .center)
        }
    }

    private var indicatorDot: some View {
        Circle()
            .fill(Color(hex: "#4314A8"))
            .frame(width: dotRadius * 2, height: dotRadius * 2)
            .shadow(color: Color.black.opacity(0.25), radius: 2, x: 2, y: 2)
            .offset(x: 0, y: -dotOffset)
            .rotationEffect(indicatorAngle, anchor: .center)
    }

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
            let dragMargin: CGFloat = 24 // allow dragging slightly outside dial
            ZStack {
                Group {
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
                    tickMarks
                }
                .rotationEffect(.degrees(dialAngle))
                // Moving indicator dot (carved look)
                indicatorDot
            }
            .compositingGroup()
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let dragPoint = value.location
                    let dx = dragPoint.x - center.x
                    let dy = dragPoint.y - center.y
                    let distance = sqrt(dx*dx + dy*dy)
                    if !isDragging {
                        if distance < innerDiameter/2 || distance > diameter/2 + dragMargin { return }
                        isDragging = true
                    }
                    let angle = atan2(dy, dx)
                    let degrees = angle * 180 / .pi
                    if let last = lastAngle {
                        var delta = degrees - last
                        if delta > 180 { delta -= 360 }
                        if delta < -180 { delta += 360 }
                        var newAngle = dialAngle + Double(delta)
                        let bpmRange = maxBPM - minBPM
                        let anglePerBPM = 360.0 / bpmRange
                        var newBPM = Int(round(Double(minBPM) + newAngle / anglePerBPM))
                        // Clamp BPM
                        if newBPM < Int(minBPM) { newBPM = Int(minBPM) }
                        if newBPM > Int(maxBPM) { newBPM = Int(maxBPM) }
                        // Freeze dialAngle at boundary if dragging further out
                        if (Int(bpm) == Int(minBPM) && newBPM == Int(minBPM) && delta < 0) {
                            // At min, dragging further down: freeze
                            // Do not update dialAngle
                        } else if (Int(bpm) == Int(maxBPM) && newBPM == Int(maxBPM) && delta > 0) {
                            // At max, dragging further up: freeze
                            // Do not update dialAngle
                        } else {
                            withAnimation(.easeOut(duration: 0.08)) {
                                dialAngle = newAngle
                            }
                        }
                        if newBPM != Int(bpm) {
                            bpm = Double(newBPM)
                            onHaptic()
                            onTick()
                        }
                    }
                    lastAngle = degrees
                }
                .onEnded { _ in
                    lastAngle = nil
                    isDragging = false
                    // Snap dialAngle to the clamped BPM
                    let bpmRange = maxBPM - minBPM
                    let anglePerBPM = 360.0 / bpmRange
                    withAnimation(.easeOut(duration: 0.12)) {
                        dialAngle = (bpm - minBPM) * anglePerBPM
                    }
                }
            )
            .onAppear {
                // Set initial dial angle based on BPM
                let bpmRange = maxBPM - minBPM
                let anglePerBPM = 360.0 / bpmRange
                dialAngle = (bpm - minBPM) * anglePerBPM
            }
            .onChange(of: bpm) { newBPM in
                // Keep dial angle in sync with BPM
                let bpmRange = maxBPM - minBPM
                let anglePerBPM = 360.0 / bpmRange
                withAnimation(.easeOut(duration: 0.08)) {
                    dialAngle = (newBPM - minBPM) * anglePerBPM
                }
            }
        }
        .frame(width: diameter, height: diameter)
    }
}

// --- Tap Tempo Button View ---
struct TapTempoButton: View {
    var onTap: () -> Void
    @State private var isPressed = false
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.18, dampingFraction: 0.5)) {
                isPressed = true
            }
            onTap()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.spring(response: 0.18, dampingFraction: 0.5)) {
                    isPressed = false
                }
            }
        }) {
            ZStack {
                Circle()
                    .fill(isPressed ? Color(hex: "#D1C7F6") : Color(hex: "#F3F0DF"))
                    .shadow(color: Color.black.opacity(0.18), radius: 4, x: 2, y: 2)
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(hex: "#8217FF"))
            }
        }
        .scaleEffect(isPressed ? 1.13 : 1.0)
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Tap Tempo")
    }
}
// --- End Tap Tempo Button View --- 
