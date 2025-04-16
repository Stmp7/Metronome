import Foundation
import AVFoundation

class MetronomeEngine: ObservableObject {
    @Published var isPlaying = false
    @Published var currentBeat = 0
    @Published var tempo: Double = 120.0 {
        didSet {
            updateTimerInterval()
        }
    }
    @Published var timeSignature: TimeSignature = .fourFour {
        didSet {
            currentBeat = 0
        }
    }
    @Published var accentPattern: [AccentLevel] = [.forte, .piano, .piano, .piano]
    
    private var timer: Timer?
    private var audioEngine: AVAudioEngine
    private var tickPlayer: AVAudioPlayerNode
    private var tockPlayer: AVAudioPlayerNode
    
    // --- Add properties to hold loaded/synthesized buffers ---
    private var firstBeatBuffer: AVAudioPCMBuffer? // For tockPlayer (Beat 0)
    private var regularBeatBuffer: AVAudioPCMBuffer? // For tickPlayer (Other beats)
    private var mezzoForteBuffer: AVAudioPCMBuffer? // Medium accent
    private var forteBuffer: AVAudioPCMBuffer? // Strong accent
    // --------------------------------------------------------
    
    init() {
        audioEngine = AVAudioEngine()
        
        // Create and setup audio nodes
        tickPlayer = AVAudioPlayerNode()
        tockPlayer = AVAudioPlayerNode()
        
        audioEngine.attach(tickPlayer)
        audioEngine.attach(tockPlayer)
        
        // Connect nodes to main mixer
        audioEngine.connect(tickPlayer, to: audioEngine.mainMixerNode, format: nil)
        audioEngine.connect(tockPlayer, to: audioEngine.mainMixerNode, format: nil)
        
        // Setup audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
        
        // Load audio files (which will populate the buffer properties)
        loadAudioFiles()
    }
    
    private func loadAudioFiles() {
        print("Creating synthesized sounds for different accent levels...")
        
        // Directly create synthesized sounds instead of trying to load files
        createSynthesizedSounds()
    }
    
    // Renamed and repurposed this function for the fallback
    private func createSynthesizedSounds() {
        print("Creating synthesized sounds...")
        let sampleRate = 44100.0
        let duration = 0.1
        
        // Create stereo buffers
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!

        // Create different pitch sounds for different accent levels
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        // Forte buffer (highest pitch and volume)
        let forteFrequency = 1200.0
        self.forteBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        if let buffer = self.forteBuffer {
             fillSineWave(buffer: buffer, frequency: forteFrequency, sampleRate: sampleRate, amplitude: 0.7)
        }
        
        // MezzoForte buffer (medium pitch and volume)
        let mezzoForteFrequency = 1000.0
        self.mezzoForteBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        if let buffer = self.mezzoForteBuffer {
             fillSineWave(buffer: buffer, frequency: mezzoForteFrequency, sampleRate: sampleRate, amplitude: 0.5)
        }
        
        // First beat sound (tock) - use forte sound
        self.firstBeatBuffer = self.forteBuffer
       
        // Regular beat sound (tick - piano level)
        let tickFrequency = 800.0
        self.regularBeatBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        if let buffer = self.regularBeatBuffer {
             fillSineWave(buffer: buffer, frequency: tickFrequency, sampleRate: sampleRate, amplitude: 0.3)
        }
        
        if forteBuffer != nil && mezzoForteBuffer != nil && regularBeatBuffer != nil {
            print("Synthesized sounds created successfully.")
        } else {
            print("ERROR: Failed to create synthesized sounds!")
        }
    }
    
    // Helper to fill a buffer with sine wave (used by createSynthesizedSounds)
    private func fillSineWave(buffer: AVAudioPCMBuffer, frequency: Double, sampleRate: Double, amplitude: Float = 0.5) {
        let frameCount = buffer.frameCapacity
        buffer.frameLength = frameCount // Set frame length
        for channel in 0..<Int(buffer.format.channelCount) {
            guard let data = buffer.floatChannelData?[channel] else { continue }
            for frame in 0..<Int(frameCount) {
                let value = sin(2.0 * .pi * frequency * Double(frame) / sampleRate)
                data[frame] = Float(value) * amplitude
            }
        }
    }
    
    private func updateTimerInterval() {
        if isPlaying {
            stop()
            start()
        }
    }
    
    func start() {
        guard !isPlaying else { return }
        
        do {
            try audioEngine.start()
            tickPlayer.play()
            tockPlayer.play()
        } catch {
            print("Failed to start audio engine: \(error)")
            return
        }
        
        isPlaying = true
        let interval = 60.0 / tempo
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.playBeat()
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        isPlaying = false
        currentBeat = 0
    }
    
    private func playBeat() {
        // Get the current accent level for this beat
        let accentLevel: AccentLevel
        if currentBeat < accentPattern.count {
            accentLevel = accentPattern[currentBeat]
        } else {
            // Default to piano if the accent pattern doesn't cover this beat
            accentLevel = .piano
        }
        
        // Skip playing sound for muted beats
        if accentLevel == .mute {
            // Just increment the beat counter and continue
            currentBeat = (currentBeat + 1) % timeSignature.beatsPerBar
            return
        }
        
        // Select the appropriate buffer based on accent level
        let bufferToPlay: AVAudioPCMBuffer?
        let playerToUse: AVAudioPlayerNode
        
        switch accentLevel {
        case .forte:
            bufferToPlay = forteBuffer
            playerToUse = tockPlayer
        case .mezzoForte:
            bufferToPlay = mezzoForteBuffer
            playerToUse = tockPlayer
        case .piano:
            bufferToPlay = regularBeatBuffer
            playerToUse = tickPlayer
        case .mute:
            // This case should have been handled above, but include for completeness
            bufferToPlay = nil
            playerToUse = tickPlayer
        }
        
        // Only play if we have a valid buffer
        if let buffer = bufferToPlay {
            // Schedule the chosen buffer onto the chosen player for immediate playback
            playerToUse.scheduleBuffer(buffer, at: nil, options: .interruptsAtLoop) { 
                // Completion handler (if needed)
            }
            playerToUse.play() // Ensure the player is playing
        }
        
        currentBeat = (currentBeat + 1) % timeSignature.beatsPerBar
    }
    
    func setTempoFromTaps(_ intervals: [TimeInterval]) {
        guard !intervals.isEmpty else { return }
        
        // Calculate average interval from last 3-4 taps
        let recentIntervals = Array(intervals.suffix(4))
        let averageInterval = recentIntervals.reduce(0, +) / Double(recentIntervals.count)
        
        // Convert to BPM (60 seconds / average interval)
        let newTempo = 60.0 / averageInterval
        
        // Clamp to valid range
        tempo = min(max(newTempo, 40.0), 240.0)
    }
    
    // Updates the accent pattern
    func updateAccentPattern(_ newPattern: [AccentLevel]) {
        accentPattern = newPattern
    }
}