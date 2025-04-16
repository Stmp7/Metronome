import Foundation
import AVFoundation

/// Sound service specifically for the new metronome design
class NewMetronomeSoundService {
    // Sound players for different accent levels
    private var forteSound: AVAudioPlayer?
    private var mezzoForteSound: AVAudioPlayer?
    private var pianoSound: AVAudioPlayer?
    
    // Flag to track initialization status
    private var isInitialized = false
    
    init() {
        setupSounds()
    }
    
    /// Setup sound files for each accent level
    private func setupSounds() {
        // Only initialize once
        guard !isInitialized else { return }
        
        // Setup each accent level sound
        forteSound = createPlayer(for: "high_wood_block")
        mezzoForteSound = createPlayer(for: "mid_wood_block")
        pianoSound = createPlayer(for: "low_wood_block")
        
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
    
    /// Play the appropriate sound for a given accent level
    func playSound(for accentLevel: AccentLevel) {
        // Skip playing for muted accents
        if accentLevel == .mute {
            return
        }
        
        // Select and play the appropriate sound
        let player: AVAudioPlayer? = {
            switch accentLevel {
            case .forte:
                return forteSound
            case .mezzoForte:
                return mezzoForteSound
            case .piano:
                return pianoSound
            case .mute:
                return nil
            }
        }()
        
        // Play the sound if available
        if let player = player {
            // Restart the sound if it's already playing
            if player.isPlaying {
                player.currentTime = 0
            }
            player.play()
        }
    }
    
    /// Play the sound for the current beat based on the accent pattern
    func playBeat(index: Int, accentPattern: [AccentLevel]) {
        guard index >= 0, index < accentPattern.count else {
            // Fallback to piano for out-of-bounds indices
            playSound(for: .piano)
            return
        }
        
        // Play the sound for the accent level at this beat
        let accentLevel = accentPattern[index]
        playSound(for: accentLevel)
    }
} 