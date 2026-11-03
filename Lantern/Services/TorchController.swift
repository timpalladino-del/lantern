import Foundation
import AVFoundation
import Observation

/// The camera LED as a signal light. Steady, slow blink, or Morse SOS.
@MainActor
@Observable
final class TorchController {
    static let shared = TorchController()

    enum Pattern: String, CaseIterable, Identifiable {
        case off, steady, slowBlink, sos
        var id: String { rawValue }
        var title: String {
            switch self {
            case .off: return "Off"
            case .steady: return "Steady"
            case .slowBlink: return "Slow blink"
            case .sos: return "SOS"
            }
        }
    }

    private(set) var pattern: Pattern = .off
    private(set) var startedAt: Date?
    private var task: Task<Void, Never>?

    var isAvailable: Bool {
        AVCaptureDevice.default(for: .video)?.hasTorch ?? false
    }

    var minutesRunning: Int {
        guard let s = startedAt else { return 0 }
        return Int(Date().timeIntervalSince(s) / 60)
    }

    func set(_ p: Pattern) {
        task?.cancel()
        task = nil
        pattern = p
        startedAt = p == .off ? nil : (startedAt ?? Date())
        switch p {
        case .off:
            torch(false)
            startedAt = nil
        case .steady:
            torch(true)
        case .slowBlink:
            task = Task { await run(sequence: [(true, 0.5), (false, 1.5)]) }
        case .sos:
            // Morse: dot = 1 unit, dash = 3, gap in letter = 1, between letters = 3, between words = 7.
            let u = 0.22
            var seq: [(Bool, Double)] = []
            for (i, letter) in [[1, 1, 1], [3, 3, 3], [1, 1, 1]].enumerated() {
                for (j, len) in letter.enumerated() {
                    seq.append((true, Double(len) * u))
                    seq.append((false, j == letter.count - 1 ? (i == 2 ? 7 * u : 3 * u) : u))
                }
            }
            task = Task { await run(sequence: seq) }
        }
    }

    func stop() { set(.off) }

    private func run(sequence: [(Bool, Double)]) async {
        while !Task.isCancelled {
            for (on, seconds) in sequence {
                if Task.isCancelled { break }
                torch(on)
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            }
        }
        torch(false)
    }

    private func torch(_ on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            if on {
                try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
            } else {
                device.torchMode = .off
            }
            device.unlockForConfiguration()
        } catch {
            // Torch unavailable (overheated or in use); leave it off.
        }
    }
}
