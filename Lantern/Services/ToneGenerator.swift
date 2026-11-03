import Foundation
import AVFoundation
import Observation

/// Synthesized sounds that ship with no audio files: an attention alarm, and noise for sleeping through a storm.
@MainActor
@Observable
final class ToneGenerator {
    static let shared = ToneGenerator()

    enum Sound: String, CaseIterable, Identifiable {
        case alarm, rain, pinkNoise, brownNoise
        var id: String { rawValue }
        var title: String {
            switch self {
            case .alarm: return "Alarm whistle"
            case .rain: return "Rain"
            case .pinkNoise: return "Soft static"
            case .brownNoise: return "Deep hum"
            }
        }
    }

    private(set) var current: Sound?
    private let engine = AVAudioEngine()
    private var source: AVAudioSourceNode?
    private var stopTask: Task<Void, Never>?

    func start(_ sound: Sound, minutes: Int? = nil) {
        stop()
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true)
        } catch { return }

        let output = engine.outputNode
        let outFormat = output.inputFormat(forBus: 0)
        let sampleRate = outFormat.sampleRate
        let render = ToneGenerator.makeRenderer(sound, sampleRate: sampleRate)

        let node = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                let v = render()
                for buffer in abl {
                    let buf = UnsafeMutableBufferPointer<Float>(buffer)
                    if frame < buf.count { buf[frame] = v }
                }
            }
            return noErr
        }
        source = node
        engine.attach(node)
        let mono = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        engine.connect(node, to: engine.mainMixerNode, format: mono)
        engine.connect(engine.mainMixerNode, to: output, format: outFormat)
        engine.mainMixerNode.outputVolume = sound == .alarm ? 1.0 : 0.6
        do {
            try engine.start()
            current = sound
        } catch {
            current = nil
        }
        if let minutes {
            stopTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(minutes) * 60_000_000_000)
                if !Task.isCancelled { self?.stop() }
            }
        }
    }

    func stop() {
        stopTask?.cancel()
        stopTask = nil
        if engine.isRunning { engine.stop() }
        if let s = source { engine.detach(s) }
        source = nil
        current = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    /// Returns a closure that produces one sample at a time. Kept outside the actor so the audio thread can call it.
    nonisolated private static func makeRenderer(_ sound: Sound, sampleRate: Double) -> () -> Float {
        var phase: Double = 0
        var t: Double = 0
        var b0 = 0.0, b1 = 0.0, b2 = 0.0, b3 = 0.0, b4 = 0.0, b5 = 0.0, b6 = 0.0
        var brown: Double = 0
        var drop: Double = 0
        var dropEnv: Double = 0
        let dt = 1.0 / sampleRate

        func white() -> Double { Double.random(in: -1...1) }
        func pink() -> Double {
            // Paul Kellet's refined pink noise filter.
            let w = white()
            b0 = 0.99886 * b0 + w * 0.0555179
            b1 = 0.99332 * b1 + w * 0.0750759
            b2 = 0.96900 * b2 + w * 0.1538520
            b3 = 0.86650 * b3 + w * 0.3104856
            b4 = 0.55000 * b4 + w * 0.5329522
            b5 = -0.7616 * b5 - w * 0.0168980
            let out = b0 + b1 + b2 + b3 + b4 + b5 + b6 + w * 0.5362
            b6 = w * 0.115926
            return out * 0.11
        }

        switch sound {
        case .alarm:
            return {
                t += dt
                // Warble between two tones four times a second; one second on, half a second off.
                let cycle = t.truncatingRemainder(dividingBy: 1.5)
                if cycle > 1.0 { return 0 }
                let freq = (Int(t * 8) % 2 == 0) ? 1000.0 : 1400.0
                phase += 2 * .pi * freq * dt
                if phase > 2 * .pi { phase -= 2 * .pi }
                return Float(sin(phase) * 0.9)
            }
        case .pinkNoise:
            return { Float(pink()) }
        case .brownNoise:
            return {
                brown = (brown + 0.02 * white()) / 1.02
                return Float(brown * 3.5)
            }
        case .rain:
            return {
                // Pink bed plus occasional short bright droplets.
                let bed = pink() * 0.7
                if Double.random(in: 0..<1) < 0.0015 { dropEnv = 1.0; drop = Double.random(in: 1500...4000) }
                var d = 0.0
                if dropEnv > 0.001 {
                    phase += 2 * .pi * drop * dt
                    if phase > 2 * .pi { phase -= 2 * .pi }
                    d = sin(phase) * dropEnv * 0.25
                    dropEnv *= 0.9985
                }
                return Float(bed + d)
            }
        }
    }
}
