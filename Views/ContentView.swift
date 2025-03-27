import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MetronomeViewModel()
    
    var body: some View {
        VStack(spacing: 30) {
            // Time Signature Picker
            Picker("Time Signature", selection: $viewModel.timeSignature) {
                ForEach(TimeSignature.allCases, id: \.self) { timeSignature in
                    Text(timeSignature.displayName).tag(timeSignature)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // Beat Indicator
            BeatIndicator(
                currentBeat: viewModel.currentBeat,
                totalBeats: viewModel.timeSignature.beatsPerMeasure,
                isPlaying: viewModel.isPlaying
            )
            
            // Tempo Controls
            VStack(spacing: 20) {
                HStack {
                    Text("\(Int(viewModel.tempo))")
                        .font(.title)
                        .frame(width: 60)
                    
                    Slider(value: $viewModel.tempo, in: 40...240, step: 1)
                        .onChange(of: viewModel.tempo) { newValue in
                            viewModel.updateTempo(newValue)
                        }
                }
                
                Button("Tap Tempo") {
                    viewModel.handleTapTempo()
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            
            // Play/Stop Button
            Button(action: viewModel.togglePlayback) {
                Image(systemName: viewModel.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(viewModel.isPlaying ? .red : .green)
            }
        }
        .padding()
    }
} 