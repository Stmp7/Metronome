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
    
    private var timer: Timer?
    private var audioEngine: AVAudioEngine
    private var tickPlayer: AVAudioPlayerNode
    private var tockPlayer: AVAudioPlayerNode
    
    // --- Add properties to hold loaded/synthesized buffers ---
    private var firstBeatBuffer: AVAudioPCMBuffer? // For tockPlayer (Beat 0)
    private var regularBeatBuffer: AVAudioPCMBuffer? // For tickPlayer (Other beats)
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
        print("Bypassing MP3 loading, using synthesized sounds for testing.") // Updated log
        
        // Directly create synthesized sounds instead of trying to load files
        createSynthesizedSounds()
        
        // -----------------------------------
    }
    
    // Renamed and repurposed this function for the fallback
    private func createSynthesizedSounds() {
        print("Creating synthesized sounds...")
        let sampleRate = 44100.0
        let duration = 0.1
        
        // Create stereo buffers
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!

        // Create first beat sound (higher pitch)
        let tockFrequency = 1000.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        self.firstBeatBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        if let buffer = self.firstBeatBuffer {
             fillSineWave(buffer: buffer, frequency: tockFrequency, sampleRate: sampleRate)
        }
       
        // Create regular beat sound (lower pitch)
        let tickFrequency = 800.0
        self.regularBeatBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
         if let buffer = self.regularBeatBuffer {
             fillSineWave(buffer: buffer, frequency: tickFrequency, sampleRate: sampleRate)
        }
        
        if firstBeatBuffer != nil && regularBeatBuffer != nil {
            print("Synthesized sounds created successfully.")
        } else {
            print("ERROR: Failed to create synthesized sounds!")
        }
    }
    
    // Helper to fill a buffer with sine wave (used by createSynthesizedSounds)
    private func fillSineWave(buffer: AVAudioPCMBuffer, frequency: Double, sampleRate: Double) {
        let frameCount = buffer.frameCapacity
        buffer.frameLength = frameCount // Set frame length
        for channel in 0..<Int(buffer.format.channelCount) {
            guard let data = buffer.floatChannelData?[channel] else { continue }
            for frame in 0..<Int(frameCount) {
                let value = sin(2.0 * .pi * frequency * Double(frame) / sampleRate)
                data[frame] = Float(value) * 0.5 // Apply amplitude
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
        // Ensure buffers are loaded before proceeding
        guard let firstBuffer = firstBeatBuffer, let regularBuffer = regularBeatBuffer else {
            print("PlayBeat Error: Buffers are not ready!")
            // Optionally stop the timer here if buffers aren't loaded
            // stop()
            return
        }
        
        let bufferToPlay: AVAudioPCMBuffer
        let playerToUse: AVAudioPlayerNode
        
        if currentBeat == 0 {
            bufferToPlay = firstBuffer  // Use tock sound
            playerToUse = tockPlayer
            // print("Playing beat 0 (Tock)") // Optional detailed log
        } else {
            bufferToPlay = regularBuffer // Use tick sound
            playerToUse = tickPlayer
            // print("Playing beat \(currentBeat) (Tick)") // Optional detailed log
        }
        
        // Schedule the chosen buffer onto the chosen player for immediate playback
        playerToUse.scheduleBuffer(bufferToPlay, at: nil, options: .interruptsAtLoop) { 
             // This completion handler isn't strictly needed for Timer-based scheduling,
             // but good to leave for potential future use or debugging.
             // print("Buffer finished playing")
         }
        playerToUse.play() // Ensure the player is playing
        
        currentBeat = (currentBeat + 1) % timeSignature.beatsPerBar // Corrected property name
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
} 