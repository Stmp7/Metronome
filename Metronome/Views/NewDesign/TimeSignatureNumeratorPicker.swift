import SwiftUI

struct TimeSignatureNumeratorPicker: View {
    @Binding var beatsPerMeasure: Int
    var onValueChanged: (() -> Void)? = nil
    
    // Common time signature numerators
    private let commonValues = [2, 3, 4, 5, 6, 7, 9, 12]
    
    // Layout constants
    private let buttonSize: CGFloat = 44
    private let cornerRadius: CGFloat = 8
    private let spacing: CGFloat = 8
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing) {
                ForEach(commonValues, id: \.self) { value in
                    Button(action: {
                        beatsPerMeasure = value
                        onValueChanged?()
                    }) {
                        Text("\(value)")
                            .font(.system(size: 18, weight: .bold))
                            .frame(width: buttonSize, height: buttonSize)
                            .background(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .fill(beatsPerMeasure == value ? 
                                          Color(hex: "#8217FF") : 
                                          Color.white.opacity(0.1))
                            )
                            .foregroundColor(beatsPerMeasure == value ? 
                                            .white : 
                                            .white.opacity(0.8))
                    }
                }
                
                // Custom value option
                Menu {
                    ForEach(1...16, id: \.self) { value in
                        Button(action: {
                            beatsPerMeasure = value
                            onValueChanged?()
                        }) {
                            Text("\(value)")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .bold))
                        .frame(width: buttonSize, height: buttonSize)
                        .background(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(Color.white.opacity(0.1))
                        )
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct TimeSignatureNumeratorPicker_Previews: PreviewProvider {
    @State static var previewValue = 4
    
    static var previews: some View {
        ZStack {
            Color(hex: "#330D81").ignoresSafeArea()
            
            TimeSignatureNumeratorPicker(
                beatsPerMeasure: $previewValue
            )
            .padding()
        }
    }
} 