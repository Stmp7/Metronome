import Foundation
import SwiftUI

class MetronomeViewModel: ObservableObject {
    @Published var tempo: Double = 120.0
    @Published var timeSignature: TimeSignature = .fourFour
    @Published var isPlaying = false
    @Published var currentBeat = 0
    @Published var tapTempoIntervals: [TimeInterval] = []
    @Published var lastTapTime: Date?
    
    private let metronomeEngine: MetronomeEngine
    
    init() {
        metronomeEngine = MetronomeEngine()
        
        // Bind metronome engine properties
        metronomeEngine.$isPlaying
            .assign(to: &$isPlaying)
        
        metronomeEngine.$currentBeat
            .assign(to: &$currentBeat)
        
        metronomeEngine.$tempo
            .assign(to: &$tempo)
        
        metronomeEngine.$timeSignature
            .assign(to: &$timeSignature)
    }
    
    func togglePlayback() {
        if isPlaying {
            metronomeEngine.stop()
        } else {
            metronomeEngine.start()
        }
    }
    
    func updateTempo(_ newTempo: Double) {
        tempo = min(max(newTempo, 40.0), 240.0)
        metronomeEngine.tempo = tempo
    }
    
    func updateTimeSignature(_ newTimeSignature: TimeSignature) {
        timeSignature = newTimeSignature
        metronomeEngine.timeSignature = newTimeSignature
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