import Foundation
import SwiftUI
import Combine
import AVFoundation

class NewMetronomeViewModel: ObservableObject {
    // MARK: - Published State
    @Published var tempo: Double = 120.0 {
        didSet {
            if isPlaying { restartTimer() }
        }
    }
    @Published var timeSignature: TimeSignature = .fourFour {
        didSet {
            updateAccentPatternForTimeSignature()
            if isPlaying { restartTimer() }
        }
    }
    @Published var isPlaying: Bool = false
    @Published var currentBeat: Int = 0
    @Published var accentPattern: [AccentLevel] = [.forte, .piano, .piano, .piano]
    @Published var nextBeatTime: AVAudioTime? = nil // For animation

    // MARK: - Private State
    private var timer: Timer? = nil
    private let soundService = NewMetronomeSoundService()
    private var cancellables = Set<AnyCancellable>()

    // --- Tap Tempo State ---
    private var tapTempoTimestamps: [Date] = []
    private let tapTempoMaxCount = 4
    private let tapTempoTimeout: TimeInterval = 3.0
    // -----------------------

    // MARK: - Timer Logic
    private func startTimer() {
        stopTimer()
        let interval = 60.0 / tempo
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.advanceBeat()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func restartTimer() {
        if isPlaying {
            startTimer()
        }
    }

    private func advanceBeat() {
        currentBeat = (currentBeat + 1) % accentPattern.count
        let accent = accentPattern[currentBeat]
        soundService.playSound(for: accent)
    }

    // MARK: - Public API
    func togglePlayback() {
        if isPlaying {
            // Stop
            isPlaying = false
            stopTimer()
        } else {
            // Start
            isPlaying = true
            currentBeat = 0
            let accent = accentPattern[currentBeat]
            soundService.playSound(for: accent)
            startTimer()
        }
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

    func setTempo(_ newTempo: Double) {
        tempo = min(max(newTempo, 40.0), 240.0)
    }

    func setTimeSignature(_ newSignature: TimeSignature) {
        timeSignature = newSignature
    }

    func updateAccent(at index: Int, to accentLevel: AccentLevel) {
        guard index >= 0, index < accentPattern.count else { return }
        accentPattern[index] = accentLevel
    }

    func cycleAccent(at index: Int) {
        guard index >= 0, index < accentPattern.count else { return }
        accentPattern[index] = accentPattern[index].next()
    }

    private func updateAccentPatternForTimeSignature() {
        let beatsPerBar = timeSignature.beatsPerBar
        var newPattern = Array(repeating: AccentLevel.piano, count: beatsPerBar)
        if !newPattern.isEmpty {
            newPattern[0] = .forte
        }
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

    // MARK: - Tap Tempo Logic
    func handleTapTempo() {
        let now = Date()
        if let lastTap = tapTempoTimestamps.last, now.timeIntervalSince(lastTap) > tapTempoTimeout {
            tapTempoTimestamps.removeAll()
        }
        tapTempoTimestamps.append(now)
        if tapTempoTimestamps.count > tapTempoMaxCount {
            tapTempoTimestamps.removeFirst()
        }
        guard tapTempoTimestamps.count >= 2 else { return }
        // Calculate intervals between taps
        let intervals = zip(tapTempoTimestamps.dropFirst(), tapTempoTimestamps).map { $0.timeIntervalSince($1) }
        let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
        let newBPM = min(max(60.0 / avgInterval, 40.0), 240.0)
        setTempo(newBPM)
    }
} 