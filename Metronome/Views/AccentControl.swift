import SwiftUI

struct AccentControl: View {
    @ObservedObject var viewModel: MetronomeViewModel
    
    private let blockHeight: CGFloat = 40
    private let spacing: CGFloat = 6
    
    var body: some View {
        GeometryReader { geo in
            let availableWidth = geo.size.width - 48  // 24px left + 24px right margin
            let blockWidth = (availableWidth - (CGFloat(viewModel.timeSignature.beatsPerBar - 1) * spacing)) / CGFloat(viewModel.timeSignature.beatsPerBar)
            
            // Define the grid layout
            let columns = Array(
                repeating: GridItem(.fixed(blockWidth), spacing: spacing),
                count: viewModel.timeSignature.beatsPerBar
            )
            
            // Using a LazyHGrid for perfect spacing
            LazyHGrid(rows: [GridItem(.fixed(blockHeight))], spacing: spacing) {
                ForEach(0..<viewModel.timeSignature.beatsPerBar, id: \.self) { index in
                    AccentBlock(
                        index: index,
                        currentBeat: viewModel.currentBeat,
                        accentLevel: viewModel.accentPattern.indices.contains(index) ? viewModel.accentPattern[index] : .piano,
                        width: blockWidth,
                        height: blockHeight,
                        onTap: {
                            // Update the accent when tapped
                            if index < viewModel.accentPattern.count {
                                var newPattern = viewModel.accentPattern
                                newPattern[index] = newPattern[index].next()
                                viewModel.accentPattern = newPattern
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 24)
        }
        .frame(height: blockHeight + 16)
        .background(Color(hex: "#1E1E1E").opacity(0.3))
        .cornerRadius(8)
    }
}

struct AccentBlock: View {
    let index: Int
    let currentBeat: Int
    let accentLevel: AccentLevel
    let width: CGFloat
    let height: CGFloat
    let onTap: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(accentLevel.color.opacity(accentLevel.fillOpacity))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            currentBeat == index ? Color.white : accentLevel.borderColor,
                            lineWidth: currentBeat == index ? 2 : accentLevel.borderWidth
                        )
                )
            
            // Show accent indicator text
            Text(accentLevel.rawValue)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white.opacity(0.8))
        }
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

struct AccentControl_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            AccentControl(viewModel: {
                let vm = MetronomeViewModel()
                vm.accentPattern = [.forte, .piano, .piano, .piano]
                return vm
            }())
            .padding()
        }
        .background(Color(hex: "#F3F0DF"))
        .previewLayout(.sizeThatFits)
    }
} 