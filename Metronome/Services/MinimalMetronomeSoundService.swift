import Foundation
import AVFoundation

class MinimalMetronomeSoundService {
    private var forteBuffer: AVAudioPCMBuffer?
    private var mezzoForteBuffer: AVAudioPCMBuffer?
    private var pianoBuffer: AVAudioPCMBuffer?
    private let audioEngine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    
    init() {
        audioEngine.attach(player)
        audioEngine.connect(player, to: audioEngine.mainMixerNode, format: nil)
        try? audioEngine.start()
        forteBuffer = Self.makeBuffer(frequency: 1200, amplitude: 0.8)
        mezzoForteBuffer = Self.makeBuffer(frequency: 1000, amplitude: 0.6)
        pianoBuffer = Self.makeBuffer(frequency: 800, amplitude: 0.4)
    }
    
    static func makeBuffer(frequency: Double, amplitude: Float) -> AVAudioPCMBuffer? {
        let sampleRate = 44100.0
        let duration = 0.09
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        let theta = 2.0 * Double.pi * frequency / sampleRate
        if let channelL = buffer.floatChannelData?[0], let channelR = buffer.floatChannelData?[1] {
            for frame in 0..<Int(frameCount) {
                let sample = Float(sin(theta * Double(frame))) * amplitude * Self.envelope(Float(frame) / Float(sampleRate), duration: Float(duration))
                channelL[frame] = sample
                channelR[frame] = sample
            }
        }
        return buffer
    }
    
    static func envelope(_ t: Float, duration: Float) -> Float {
        // Simple percussive envelope: fast attack, exponential decay
        let attack: Float = 0.01
        if t < attack { return t / attack }
        let decay: Float = duration - attack
        return exp(-4 * (t - attack) / decay)
    }
    
    func playAccent(_ accent: AccentLevel) {
        let buffer: AVAudioPCMBuffer?
        switch accent {
        case .forte: buffer = forteBuffer
        case .mezzoForte: buffer = mezzoForteBuffer
        case .piano: buffer = pianoBuffer
        case .mute: return // No sound
        }
        guard let buffer = buffer else { return }
        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: .interruptsAtLoop, completionHandler: nil)
        if !player.isPlaying {
            player.play()
        }
    }
} 