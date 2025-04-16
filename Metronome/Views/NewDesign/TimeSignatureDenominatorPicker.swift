import SwiftUI

struct TimeSignatureDenominatorPicker: View {
    @Binding var noteValue: Int
    
    // Common time signature denominators
    private let commonValues = [2, 4, 8, 16]
    
    // Layout constants
    private let buttonSize: CGFloat = 44
    private let cornerRadius: CGFloat = 8
    private let spacing: CGFloat = 8
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(commonValues, id: \.self) { value in
                Button(action: {
                    noteValue = value
                }) {
                    Text("\(value)")
                        .font(.system(size: 18, weight: .bold))
                        .frame(width: buttonSize, height: buttonSize)
                        .background(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(noteValue == value ? 
                                      Color(hex: "#8217FF") : 
                                      Color.white.opacity(0.1))
                        )
                        .foregroundColor(noteValue == value ? 
                                        .white : 
                                        .white.opacity(0.8))
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct TimeSignatureDenominatorPicker_Previews: PreviewProvider {
    @State static var previewValue = 4
    
    static var previews: some View {
        ZStack {
            Color(hex: "#330D81").ignoresSafeArea()
            
            TimeSignatureDenominatorPicker(
                noteValue: $previewValue
            )
            .padding()
        }
    }
} 