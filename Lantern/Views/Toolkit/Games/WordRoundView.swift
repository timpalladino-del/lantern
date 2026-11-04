import SwiftUI
import CoreMotion

/// Heads up (phone on the forehead, tilt to answer) and act it out (charades) share one screen.
struct WordRoundView: View {
    enum Mode { case headsUp, actItOut }
    let mode: Mode

    @State private var category: GamesLibrary.WordCategory = GamesLibrary.categories[0]
    @State private var roundLength = 60
    @State private var phase: Phase = .setup
    @State private var queue: [String] = []
    @State private var word = ""
    @State private var got: [String] = []
    @State private var passed: [String] = []
    @State private var remaining = 60
    @State private var running = false
    @State private var flash: Color?
    @State private var answers = 0
    @State private var motion = MotionTilt()

    enum Phase { case setup, countdown, playing, results }

    private var title: String { mode == .headsUp ? "Heads up" : "Act it out" }

    var body: some View {
        Group {
            switch phase {
            case .setup: setup
            case .countdown: countdown
            case .playing: playing
            case .results: results
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { motion.stop(); UIApplication.shared.isIdleTimerDisabled = false }
        .sensoryFeedback(.impact(weight: .heavy), trigger: answers)
    }

    private var setup: some View {
        List {
            Section("Category") {
                ForEach(GamesLibrary.categories.filter { mode == .actItOut ? $0.actable : true }) { c in
                    Button {
                        category = c
                    } label: {
                        HStack {
                            Label(c.title, systemImage: c.symbol).foregroundStyle(.primary)
                            Spacer()
                            if c.id == category.id { Image(systemName: "checkmark").foregroundStyle(Color.accentColor) }
                        }
                    }
                }
            }
            Section("Round") {
                Picker("Length", selection: $roundLength) {
                    Text("30 seconds").tag(30); Text("60 seconds").tag(60); Text("90 seconds").tag(90)
                }
            }
            Section {
                GameUI.bigButton("Start", symbol: "play.fill") { begin() }
                    .listRowBackground(Color.clear).listRowInsets(EdgeInsets())
            } footer: {
                Text(mode == .headsUp
                     ? "Hold the phone against your forehead, screen facing out. Everyone else gives clues. Tilt the phone down for right, up to pass. Tap works too."
                     : "One person reads the word and acts it out. No words, no sounds, no pointing at things. Everyone else guesses. Tap when they get it.")
            }
        }
    }

    private var countdown: some View {
        VStack(spacing: 20) {
            Spacer()
            Text(mode == .headsUp ? "Phone to your forehead" : "Get ready").font(.title2.weight(.semibold))
            Text("\(remaining)").font(.system(size: 96, weight: .bold, design: .rounded)).monospacedDigit().contentTransition(.numericText())
            Spacer()
        }
        .task {
            for n in [3, 2, 1] {
                remaining = n
                try? await Task.sleep(for: .seconds(1))
            }
            startPlay()
        }
    }

    private var playing: some View {
        ZStack {
            (flash ?? Color(uiColor: .systemBackground)).ignoresSafeArea().animation(.easeOut(duration: 0.25), value: flash)
            VStack(spacing: 24) {
                HStack {
                    Label(category.title, systemImage: category.symbol).font(.subheadline).foregroundStyle(.secondary)
                    Spacer()
                    CountdownTimer(seconds: roundLength, running: $running, remaining: $remaining) { finish() }
                }
                .padding(.horizontal)
                Spacer()
                Text(word)
                    .font(.system(size: mode == .headsUp ? 56 : 44, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center).minimumScaleFactor(0.5).lineLimit(3)
                    .padding(.horizontal, 24)
                    .contentTransition(.numericText())
                Spacer()
                HStack(spacing: 12) {
                    GameUI.bigButton("Pass", symbol: "arrow.right", tint: Color.secondary) { pass() }
                    GameUI.bigButton("Got it", symbol: "checkmark", tint: Color.moss) { correct() }
                }
                .padding(.horizontal)
                Text("\(got.count) right · \(passed.count) passed").font(.footnote).foregroundStyle(.secondary).padding(.bottom, 8)
            }
        }
    }

    private var results: some View {
        List {
            Section {
                Text("\(got.count) right in \(roundLength) seconds").font(.title2.weight(.bold)).frame(maxWidth: .infinity)
            }
            if !got.isEmpty { Section("Got") { ForEach(got, id: \.self) { Text($0) } } }
            if !passed.isEmpty { Section("Passed") { ForEach(passed, id: \.self) { Text($0).foregroundStyle(.secondary) } } }
            Section {
                GameUI.bigButton("Next player", symbol: "arrow.counterclockwise") { begin() }
                    .listRowBackground(Color.clear).listRowInsets(EdgeInsets())
                Button("Change category") { phase = .setup }.frame(maxWidth: .infinity)
            }
        }
    }

    private func begin() {
        queue = category.words.shuffled()
        got = []; passed = []
        phase = .countdown
        UIApplication.shared.isIdleTimerDisabled = true
    }

    private func startPlay() {
        remaining = roundLength
        word = queue.popLast() ?? ""
        running = true
        phase = .playing
        if mode == .headsUp {
            motion.start(onDown: { correct() }, onUp: { pass() })
        }
    }

    private func correct() {
        guard phase == .playing else { return }
        got.append(word); answers += 1
        flash = Color.moss.opacity(0.35)
        advance()
    }

    private func pass() {
        guard phase == .playing else { return }
        passed.append(word); answers += 1
        flash = Color.signal.opacity(0.25)
        advance()
    }

    private func advance() {
        if queue.isEmpty { queue = category.words.shuffled() }
        word = queue.popLast() ?? ""
        Task { try? await Task.sleep(for: .milliseconds(350)); flash = nil }
    }

    private func finish() {
        motion.stop()
        running = false
        phase = .results
        UIApplication.shared.isIdleTimerDisabled = false
    }
}

/// Reads gravity on the phone's z axis. Screen toward the floor fires onDown, toward the sky fires onUp,
/// and nothing fires again until the phone is back upright.
@Observable
final class MotionTilt {
    private let manager = CMMotionManager()
    private var armed = true

    func start(onDown: @escaping () -> Void, onUp: @escaping () -> Void) {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] m, _ in
            guard let self, let z = m?.gravity.z else { return }
            if armed, z > 0.65 { armed = false; onDown() }
            else if armed, z < -0.65 { armed = false; onUp() }
            else if !armed, abs(z) < 0.35 { armed = true }
        }
    }

    func stop() { manager.stopDeviceMotionUpdates(); armed = true }
}
