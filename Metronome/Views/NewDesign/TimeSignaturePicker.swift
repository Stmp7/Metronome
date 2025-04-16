import SwiftUI

// Note value for time signature denominator
enum NoteValue: String, CaseIterable, Identifiable {
    case whole = "Whole"
    case half = "Half"
    case quarter = "Quarter"
    case eighth = "Eighth"
    case sixteenth = "Sixteenth"
    case thirtySecond = "Thirty-second"
    
    var id: String { self.rawValue }
    
    var denominator: Int {
        switch self {
        case .whole: return 1
        case .half: return 2
        case .quarter: return 4
        case .eighth: return 8
        case .sixteenth: return 16
        case .thirtySecond: return 32
        }
    }
    
    var symbol: String {
        switch self {
        case .whole: return "𝅝"
        case .half: return "𝅗𝅥"
        case .quarter: return "♩"
        case .eighth: return "♪"
        case .sixteenth: return "𝅘𝅥𝅯"
        case .thirtySecond: return "𝅘𝅥𝅰"
        }
    }
}

struct TimeSignaturePicker: View {
    @Binding var beatsPerMeasure: Int
    @Binding var noteValue: Int
    
    // Available options
    private let beatOptions = Array(1...16)  // From 1 to 16 beats
    private let noteOptions = [1, 2, 4, 8, 16, 32]  // Common note values (powers of 2)
    
    var body: some View {
        VStack(spacing: 12) {
            // Time Signature Card
            ZStack {
                // Card background
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "#1F1444"))
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                
                // Content
                HStack(spacing: 0) {
                    // Beats picker column
                    VStack(spacing: 8) {
                        Text("Beats")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Picker("Beats", selection: $beatsPerMeasure) {
                            ForEach(beatOptions, id: \.self) { beat in
                                Text("\(beat)")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .labelsHidden()
                        .frame(height: 120)
                        .clipped()
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Divider
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 1, height: 150)
                        .padding(.vertical, 8)
                    
                    // Notes picker column
                    VStack(spacing: 8) {
                        Text("Notes")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Picker("Notes", selection: $noteValue) {
                            ForEach(noteOptions, id: \.self) { note in
                                Text("\(note)")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .labelsHidden()
                        .frame(height: 120)
                        .clipped()
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(16)
            }
            
            // Time Signature Display
            HStack(spacing: 12) {
                Text("Time Signature:")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.system(size: 16))
                
                Text("\(beatsPerMeasure)/\(noteValue)")
                    .foregroundColor(.white)
                    .font(.system(size: 20, weight: .bold))
            }
            .padding(.top, 4)
        }
    }
}

struct TimeSignaturePicker_Previews: PreviewProvider {
    @State static var beats = 4
    @State static var note = 4
    
    static var previews: some View {
        ZStack {
            Color(hex: "#330D81").edgesIgnoringSafeArea(.all) // Background color
            
            VStack {
                TimeSignaturePicker(
                    beatsPerMeasure: $beats,
                    noteValue: $note
                )
                .padding(24)
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
} 