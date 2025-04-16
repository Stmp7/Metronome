//
//  MetronomeApp.swift
//  Metronome
//
//  Created by Ran Zabaro on 30/03/2025.
//

import SwiftUI

// Define an enum to represent the available designs
// Moved OUTSIDE the struct to make it globally accessible
enum Design {
    case classic
    case new
}

@main
struct MetronomeApp: App {
    // Create the ViewModel instance here so it can be shared
    @StateObject private var metronomeViewModel = MetronomeViewModel()
    // State variable to track the current design
    @State private var currentDesign: Design = .classic

    var body: some Scene {
        WindowGroup {
            // Conditionally render the view based on the currentDesign state
            Group {
                if currentDesign == .classic {
                    // Pass the shared ViewModel and the design state binding
                    ContentView(viewModel: metronomeViewModel, currentDesign: $currentDesign)
                } else {
                    // Pass only the design state binding for the minimal view
                    NewMetronomeView(currentDesign: $currentDesign)
                }
            }
            .onAppear {
                // Optional: Print when the main app view appears
                print("MetronomeApp WindowGroup appeared. Initial design: \(currentDesign)")
                
                // Initialize the accent pattern for the current time signature
                metronomeViewModel.updateAccentPatternForTimeSignature()
            }
            // Removed .preferredColorScheme(.light) unless specifically needed
        }
    }
}
