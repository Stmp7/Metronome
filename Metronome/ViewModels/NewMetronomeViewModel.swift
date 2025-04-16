import Foundation
import SwiftUI
import Combine

class NewMetronomeViewModel: ObservableObject {
    // Reuse the existing metronome ViewModel for core functionality
    private let metronomeViewModel: MetronomeViewModel
    
    // Custom accent pattern for the new design
    @Published var accentPattern: [AccentLevel] = [.forte, .piano, .piano, .piano]
    
    // Sound service specific to the new design
    private let soundService = NewMetronomeSoundService()
    
    // Passthrough published properties from the base viewModel
    @Published var tempo: Double = 120.0
    @Published var timeSignature: TimeSignature = .fourFour
    @Published var isPlaying = false
    @Published var currentBeat = 0
    
    // Subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    init(baseViewModel: MetronomeViewModel = MetronomeViewModel()) {
        self.metronomeViewModel = baseViewModel
        setupBindings()
        setupDefaultAccentPattern()
    }
    
    /// Setup two-way bindings with the base viewModel
    private func setupBindings() {
        // Forward changes from base viewModel to this viewModel
        metronomeViewModel.$tempo
            .assign(to: &$tempo)
        
        metronomeViewModel.$timeSignature
            .assign(to: &$timeSignature)
        
        metronomeViewModel.$isPlaying
            .assign(to: &$isPlaying)
        
        // Handle beat changes and play the appropriate sound
        metronomeViewModel.$currentBeat
            .sink { [weak self] newBeat in
                guard let self = self else { return }
                self.currentBeat = newBeat
                
                // Only play sounds when playing
                if self.isPlaying {
                    self.soundService.playBeat(index: newBeat, accentPattern: self.accentPattern)
                }
            }
            .store(in: &cancellables)
        
        // Forward changes from this viewModel back to the base viewModel
        $tempo
            .dropFirst() // Skip initial value
            .sink { [weak self] newTempo in
                self?.metronomeViewModel.updateTempo(newTempo)
            }
            .store(in: &cancellables)
        
        $timeSignature
            .dropFirst() // Skip initial value
            .sink { [weak self] newSignature in
                self?.metronomeViewModel.timeSignature = newSignature
                self?.setupDefaultAccentPattern()
            }
            .store(in: &cancellables)
    }
    
    /// Setup the default accent pattern based on time signature
    func setupDefaultAccentPattern() {
        let beatsPerBar = timeSignature.beatsPerBar
        var newPattern = Array(repeating: AccentLevel.piano, count: beatsPerBar)
        
        // First beat is always forte
        if !newPattern.isEmpty {
            newPattern[0] = .forte
        }
        
        // For compound meters, add mezzoForte accents
        let subdivision = timeSignature.subdivision
        if subdivision > 1 {
            for i in stride(from: subdivision, to: beatsPerBar, by: subdivision) {
                if i < beatsPerBar {
                    newPattern[i] = .mezzoForte
                }
            }
        }
        
        // Try to preserve existing pattern for beats that still exist
        var finalPattern = newPattern
        for i in 0..<min(accentPattern.count, beatsPerBar) {
            finalPattern[i] = accentPattern[i]
        }
        
        accentPattern = finalPattern
    }
    
    // Playback control functions
    func togglePlayback() {
        metronomeViewModel.togglePlayback()
    }
    
    func start() {
        if !isPlaying {
            togglePlayback()
        }
    }
    
    func stop() {
        if isPlaying {
            togglePlayback()
        }
    }
    
    // Update an individual beat's accent level
    func updateAccent(at index: Int, to accentLevel: AccentLevel) {
        guard index >= 0, index < accentPattern.count else { return }
        accentPattern[index] = accentLevel
    }
    
    // Cycle the accent for a beat to the next level
    func cycleAccent(at index: Int) {
        guard index >= 0, index < accentPattern.count else { return }
        accentPattern[index] = accentPattern[index].next()
    }
} 