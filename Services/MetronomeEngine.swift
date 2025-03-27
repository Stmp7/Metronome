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
        
        // Load audio files
        loadAudioFiles()
    }
    
    private func loadAudioFiles() {
        // TODO: Load actual audio files
        // For now, we'll create simple sine wave buffers
        let sampleRate = 44100.0
        let duration = 0.1
        let frequency = 1000.0
        
        let tickBuffer = createSineWaveBuffer(sampleRate: sampleRate, duration: duration, frequency: frequency)
        let tockBuffer = createSineWaveBuffer(sampleRate: sampleRate, duration: duration, frequency: frequency * 0.8)
        
        tickPlayer.scheduleBuffer(tickBuffer, at: nil)
        tockPlayer.scheduleBuffer(tockBuffer, at: nil)
    }
    
    private func createSineWaveBuffer(sampleRate: Double, duration: Double, frequency: Double) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        
        let data = buffer.floatChannelData![0]
        for frame in 0..<Int(frameCount) {
            let value = sin(2.0 * .pi * frequency * Double(frame) / sampleRate)
            data[frame] = Float(value)
        }
        
        buffer.frameLength = frameCount
        return buffer
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
        if currentBeat == 0 {
            tockPlayer.reset()
            tockPlayer.play()
        } else {
            tickPlayer.reset()
            tickPlayer.play()
        }
        
        currentBeat = (currentBeat + 1) % timeSignature.beatsPerMeasure
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