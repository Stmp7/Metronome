//
//  ContentView.swift
//  Metronome
//
//  Created by Ran Zabaro on 30/03/2025.
//

import SwiftUI

struct ContentView: View {
    // Use @ObservedObject since the ViewModel is now created by the parent (MetronomeApp)
    @ObservedObject var viewModel: MetronomeViewModel
    // Add binding to control design switching
    @Binding var currentDesign: Design

    var body: some View {
        VStack(spacing: 20) { // Reduced spacing slightly to accommodate button

            // Button to switch to the new design - Placed at the top for visibility
            Button("Switch to New Design") {
                currentDesign = .new // Update the state variable
            }
            .padding(.top) // Add padding at the top
            .buttonStyle(.borderedProminent)
            // .tint(Color(hex: "#8217FF")) // Temporarily commented out to avoid compiler bug

            // Time signature selector
            Picker("Time Signature", selection: $viewModel.timeSignature) {
                ForEach(TimeSignature.allCases, id: \.self) { timeSignature in
                    Text(timeSignature.description)
                        .tag(timeSignature)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // --- Tempo Slider Control --- 
            VStack {
                Slider(
                    value: $viewModel.tempo,
                    in: 40...240, // Define the BPM range
                    step: 1.0 // Adjust BPM by whole numbers
                ) {
                    Text("Tempo") // Label for accessibility
                }
                .tint(Color(hex: "#8217FF")) // Apply accent color
                
                Text("\(Int(viewModel.tempo)) BPM")
                    .font(.system(size: 24, weight: .bold)) // Slightly smaller font for slider context
                    .foregroundColor(Color(hex: "#110034"))
                    .monospacedDigit()
            }
            .padding(.horizontal, 40) // Add some horizontal padding
            // --- End Tempo Slider Control ---
            
            // Add the new Accent Control
            VStack(alignment: .leading) {
                Text("Accent Pattern")
                    .font(.headline)
                    .foregroundColor(Color(hex: "#110034"))
                    .padding(.horizontal)
                
                AccentControl(viewModel: viewModel)
                    .frame(height: 50)
                    .padding(.horizontal)
            }
            
            // Beat indicator with play/stop button
            BeatIndicator(
                currentBeat: viewModel.currentBeat,
                totalBeats: viewModel.timeSignature.beatsPerBar,
                isPlaying: viewModel.isPlaying,
                onPlayStop: { viewModel.togglePlayback() }
            )
            // Add some padding below the beat indicator if needed
            .padding(.bottom)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#F3F0DF").ignoresSafeArea())
        .onAppear {
            print("ContentView appeared (Updated Version)") // Modified log for confirmation
            // Initialize accent pattern when view appears
            viewModel.updateAccentPatternForTimeSignature()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    // Create a dummy state for preview
    @State static var previewDesign: Design = .classic
    static var previews: some View {
        // Update preview to pass a ViewModel instance and the dummy state binding
        ContentView(
            viewModel: MetronomeViewModel(),
            currentDesign: $previewDesign
        )
    }
}
