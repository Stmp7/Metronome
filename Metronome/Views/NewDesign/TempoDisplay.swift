import SwiftUI

// Helper to convert BPM to a musical tempo marking
enum TempoMarking: String {
    case largo = "Largo"
    case adagio = "Adagio"
    case andante = "Andante"
    case moderato = "Moderato" 
    case allegro = "Allegro"
    case vivace = "Vivace"
    case presto = "Presto"
    
    // Get tempo marking based on BPM
    static func forBPM(_ bpm: Double) -> TempoMarking {
        switch bpm {
        case 40..<60: return .largo
        case 60..<76: return .adagio
        case 76..<108: return .andante
        case 108..<120: return .moderato
        case 120..<168: return .allegro
        case 168..<200: return .vivace
        default: return .presto
        }
    }
}

struct TempoDisplay: View {
    let bpm: Double
    let onTap: () -> Void
    
    // Computed property to get the tempo marking
    private var tempoMarking: TempoMarking {
        TempoMarking.forBPM(bpm)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // BPM Display
            Text("\(Int(bpm))")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .monospacedDigit()
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap()
                }
            
            // Tempo Marking
            Text(tempoMarking.rawValue)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(Color.white.opacity(0.8))
        }
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
    }
}

// Numeric keypad for direct BPM entry
struct TempoKeypad: View {
    @Binding var tempo: Double
    var onCancel: () -> Void = {}
    var onDone: () -> Void = {}
    @State private var enteredValue: String = ""
    private let minBPM: Double = 40
    private let maxBPM: Double = 240
    var body: some View {
        VStack(spacing: 20) {
            Text("Enter BPM")
                .font(.title)
                .foregroundColor(.white)
                .padding(.top)
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                Text(enteredValue.isEmpty ? "\(Int(tempo))" : enteredValue)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()
                    .padding()
            }
            .frame(height: 80)
            .padding(.horizontal)
            VStack(spacing: 15) {
                ForEach(0..<3) { row in
                    HStack(spacing: 15) {
                        ForEach(1...3, id: \.self) { col in
                            let number = row * 3 + col
                            DigitButton(digit: "\(number)") {
                                appendDigit("\(number)")
                            }
                        }
                    }
                }
                HStack(spacing: 15) {
                    DigitButton(digit: "C", isSpecial: true) {
                        enteredValue = ""
                    }
                    DigitButton(digit: "0") {
                        appendDigit("0")
                    }
                    DigitButton(digit: "⌫", isSpecial: true) {
                        if !enteredValue.isEmpty {
                            enteredValue.removeLast()
                        }
                    }
                }
            }
            .padding(.horizontal)
            HStack(spacing: 16) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(SecondaryDrawerButtonStyle())
                Button("Done") {
                    applyTempo()
                    onDone()
                }
                .buttonStyle(PrimaryDrawerButtonStyle())
                .disabled(enteredValue.isEmpty)
            }
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#330D81"))
        .onAppear { enteredValue = "" }
    }
    private func appendDigit(_ digit: String) {
        if enteredValue.count < 3 {
            enteredValue += digit
        }
    }
    private func applyTempo() {
        if let newTempo = Double(enteredValue) {
            tempo = min(max(newTempo, minBPM), maxBPM)
        }
    }
}

// Button style for digit buttons
struct DigitButton: View {
    let digit: String
    var isSpecial: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(digit)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 80, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSpecial ? Color(hex: "#4D267A") : Color.white.opacity(0.2))
                )
        }
    }
}

// Button style for action buttons
struct ActionButtonStyle: ButtonStyle {
    var isDestructive: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 30)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isDestructive ? Color(hex: "#CC3366").opacity(0.8) : Color(hex: "#4D267A"))
                    .opacity(configuration.isPressed ? 0.7 : 1)
            )
    }
}

// Preview provider for the Tempo Display and Keypad
struct TempoDisplay_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State private var showKeypad = false
        @State private var tempo: Double = 120
        
        var body: some View {
            ZStack {
                // Background
                Color(hex: "#330D81").ignoresSafeArea()
                
                // Tempo display
                TempoDisplay(bpm: tempo) {
                    showKeypad = true
                }
                .sheet(isPresented: $showKeypad) {
                    TempoKeypad(tempo: $tempo)
                }
            }
        }
    }
    
    static var previews: some View {
        PreviewWrapper()
    }
} 