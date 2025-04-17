import Foundation
import AVFoundation

/// Sound service specifically for the new metronome design
class NewMetronomeSoundService {
    // Sound players for different accent levels
    private var forteSound: AVAudioPlayer?
    private var mezzoForteSound: AVAudioPlayer?
    private var pianoSound: AVAudioPlayer?
    // Synth fallback players
    private var forteSynth: AVAudioPlayer?
    private var mezzoForteSynth: AVAudioPlayer?
    private var pianoSynth: AVAudioPlayer?
    // Flag to track initialization status
    private var isInitialized = false
    
    init() {
        setupSounds()
    }
    
    /// Setup sound files for each accent level, with synth fallback
    private func setupSounds() {
        guard !isInitialized else { return }
        // Try to load each file, fallback to synth if missing
        forteSound = createPlayer(for: "high_wood_block")
        if forteSound == nil { forteSynth = createSynthPlayer(frequency: 1200.0, amplitude: 0.7) }
        mezzoForteSound = createPlayer(for: "mid_wood_block")
        if mezzoForteSound == nil { mezzoForteSynth = createSynthPlayer(frequency: 1000.0, amplitude: 0.5) }
        pianoSound = createPlayer(for: "low_wood_block")
        if pianoSound == nil { pianoSynth = createSynthPlayer(frequency: 800.0, amplitude: 0.3) }
        isInitialized = true
    }
    
    /// Helper to create an audio player for a given sound file
    private func createPlayer(for filename: String) -> AVAudioPlayer? {
        guard let soundURL = Bundle.main.url(forResource: filename, withExtension: "wav", subdirectory: "SFX") else {
            print("Could not find sound file: \(filename)")
            return nil
        }
        do {
            let player = try AVAudioPlayer(contentsOf: soundURL)
            player.prepareToPlay()
            return player
        } catch {
            print("Failed to create player for \(filename): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Helper to create a synthesized tone as an AVAudioPlayer
    private func createSynthPlayer(frequency: Double, amplitude: Float) -> AVAudioPlayer? {
        let sampleRate = 44100.0
        let duration = 0.1
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        if let data = buffer.floatChannelData?[0] {
            for frame in 0..<Int(frameCount) {
                data[frame] = sin(Float(2.0 * .pi * frequency * Double(frame) / sampleRate)) * amplitude
            }
        }
        // Write buffer to a temp file and load as AVAudioPlayer
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".wav")
        do {
            try writeBuffer(buffer, to: tempURL, format: format)
            let player = try AVAudioPlayer(contentsOf: tempURL)
            player.prepareToPlay()
            return player
        } catch {
            print("Failed to create synth player: \(error)")
            return nil
        }
    }
    
    /// Write AVAudioPCMBuffer to a .wav file
    private func writeBuffer(_ buffer: AVAudioPCMBuffer, to url: URL, format: AVAudioFormat) throws {
        guard let file = try? AVAudioFile(forWriting: url, settings: format.settings) else { throw NSError(domain: "SynthWrite", code: 1) }
        try file.write(from: buffer)
    }
    
    /// Play the appropriate sound for a given accent level
    func playSound(for accentLevel: AccentLevel) {
        if accentLevel == .mute { return }
        let player: AVAudioPlayer? = {
            switch accentLevel {
            case .forte:
                return forteSound ?? forteSynth
            case .mezzoForte:
                return mezzoForteSound ?? mezzoForteSynth
            case .piano:
                return pianoSound ?? pianoSynth
            case .mute:
                return nil
            }
        }()
        if let player = player {
            if player.isPlaying { player.currentTime = 0 }
            player.play()
        }
    }
    
    /// Play the sound for the current beat based on the accent pattern
    func playBeat(index: Int, accentPattern: [AccentLevel]) {
        guard index >= 0, index < accentPattern.count else {
            playSound(for: .piano)
            return
        }
        let accentLevel = accentPattern[index]
        playSound(for: accentLevel)
    }
} 