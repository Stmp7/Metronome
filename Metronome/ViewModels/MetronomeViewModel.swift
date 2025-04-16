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
    @Published var accentPattern: [AccentLevel] = [.forte, .piano, .piano, .piano]
    
    private let metronomeEngine: MetronomeEngine
    private var cancellables = Set<AnyCancellable>()
    private var suspendAccentPatternUpdate = false
    
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
        
        // Bind accent pattern from engine
        metronomeEngine.$accentPattern
            .receive(on: RunLoop.main)
            .assign(to: &$accentPattern)
        
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
                if self?.suspendAccentPatternUpdate == false {
                    self?.updateAccentPatternForTimeSignature()
                }
            }
            .store(in: &cancellables)
            
        // Forward accent pattern changes to the engine
        $accentPattern
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] newPattern in
                self?.metronomeEngine.updateAccentPattern(newPattern)
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
    
    // Set up the default accent pattern based on the time signature
    func updateAccentPatternForTimeSignature() {
        let beatsPerBar = timeSignature.beatsPerBar
        var newAccents = Array(repeating: AccentLevel.piano, count: beatsPerBar)
        
        // First beat is always forte
        if !newAccents.isEmpty {
            newAccents[0] = .forte
        }
        
        // For compound meters (e.g. 6/8, 9/8, 12/8), add secondary accents
        if timeSignature.subdivision > 1 {
            for i in stride(from: timeSignature.subdivision, to: beatsPerBar, by: timeSignature.subdivision) {
                if i < beatsPerBar {
                    newAccents[i] = .mezzoForte
                }
            }
        }
        
        accentPattern = newAccents
    }
    
    // Methods to control accent pattern update suspension
    func suspendAccentPatternUpdates() {
        suspendAccentPatternUpdate = true
    }
    func resumeAccentPatternUpdates() {
        suspendAccentPatternUpdate = false
    }
    
    // Atomic update for time signature and accent pattern
    func applyTimeSignatureAndAccentPattern(_ timeSignature: TimeSignature, _ accentPattern: [AccentLevel]) {
        suspendAccentPatternUpdates()
        self.timeSignature = timeSignature
        self.accentPattern = accentPattern
        resumeAccentPatternUpdates()
    }
} 