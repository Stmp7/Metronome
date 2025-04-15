import SwiftUI

// Helper extension to initialize Color from hex string
// Removed because it's already defined elsewhere in the project
// extension Color {
//    init(hex: String) {
//        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
//        var int: UInt64 = 0
//        Scanner(string: hex).scanHexInt64(&int)
//        let a, r, g, b: UInt64
//        switch hex.count {
//        case 3: // RGB (12-bit)
//            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
//        case 6: // RGB (24-bit)
//            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
//        case 8: // ARGB (32-bit)
//            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
//        default:
//            (a, r, g, b) = (255, 0, 0, 0) // Default to black
//        }
//        self.init(
//            .sRGB,
//            red: Double(r) / 255,
//            green: Double(g) / 255,
//            blue:  Double(b) / 255,
//            opacity: Double(a) / 255
//        )
//    }
// }


struct NewMetronomeView: View {
    @ObservedObject var viewModel: MetronomeViewModel
    @Binding var currentDesign: Design

    var body: some View {
        ZStack {
            // Set the desired background color
            Color(hex: "#330D81")
                .ignoresSafeArea() // Make background cover entire screen

            // Add the button to switch back, placed somewhere accessible
            VStack {
                Spacer() // Push button to the bottom
                Button("Switch to Classic Design") {
                    currentDesign = .classic // Update the state variable
                }
                .padding()
                .buttonStyle(.bordered)
                .tint(.white) // Make button text visible on dark background
            }
            .padding(.bottom, 20) // Add some padding from the bottom edge
        }
        .onAppear {
            print("NewMetronomeView appeared") // Add log to confirm appearance
        }
    }
}

struct NewMetronomeView_Previews: PreviewProvider {
    @State static var previewDesign: Design = .new
    static var previews: some View {
        NewMetronomeView(
            viewModel: MetronomeViewModel(),
            currentDesign: $previewDesign
        )
    }
}
