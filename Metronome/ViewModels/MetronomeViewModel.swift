import Foundation
import SwiftUI
import Combine

class MetronomeViewModel: ObservableObject {
    @Published var tempo: Double = 120.0
    @Published var timeSignature: TimeSignature = .fourFour
    @Published var isPlaying = false
    @Published var currentBeat = 0
    @Published var tapTempoIntervals: [TimeInterval] = []
    @Published var lastTapTime: Date?
    
    private let metronomeEngine: MetronomeEngine
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        metronomeEngine = MetronomeEngine()
        
        // Bind metronome engine properties TO ViewModel properties
        metronomeEngine.$isPlaying
            .assign(to: &$isPlaying)
        
        metronomeEngine.$currentBeat
            .assign(to: &$currentBeat)
        
        metronomeEngine.$tempo
            .receive(on: RunLoop.main)
            .assign(to: &$tempo)
        
        // Remove the binding from Engine's timeSignature back to the ViewModel's timeSignature
        /*
        metronomeEngine.$timeSignature
            .receive(on: RunLoop.main)
            .assign(to: &$timeSignature)
        */
        
        // Subscribe to ViewModel's timeSignature changes and update the Engine (Keep this)
        $timeSignature
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] newSignature in
                print("ViewModel timeSignature changed to: \(newSignature). Updating engine.")
                self?.metronomeEngine.timeSignature = newSignature
            }
            .store(in: &cancellables)
    }
    
    func togglePlayback() {
        if isPlaying {
            metronomeEngine.stop()
        } else {
            metronomeEngine.start()
        }
    }
    
    func updateTempo(_ newTempo: Double) {
        metronomeEngine.tempo = min(max(newTempo, 40.0), 240.0)
    }
    
    func handleTapTempo() {
        let now = Date()
        
        if let lastTap = lastTapTime {
            let interval = now.timeIntervalSince(lastTap)
            tapTempoIntervals.append(interval)
            
            // Keep only the last 4 intervals
            if tapTempoIntervals.count > 4 {
                tapTempoIntervals.removeFirst()
            }
            
            metronomeEngine.setTempoFromTaps(tapTempoIntervals)
        }
        
        lastTapTime = now
    }
} 