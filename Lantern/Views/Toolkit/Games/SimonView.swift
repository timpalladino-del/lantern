import SwiftUI

/// Four pads light up in a pattern that grows by one each round. Tap it back.
struct SimonView: View {
    @State private var game = SimonGame()
    @State private var lit: Int?
    @State private var showing = false
    @State private var status = "Tap Start and watch."
    @State private var over = false
    @State private var presses = 0
    @State private var best: Int = UserDefaults.standard.integer(forKey: "games.simonBest")

    private let colors: [Color] = [Color.accentColor, Color.moss, Color.signal, Color.primary]
    private let names = ["blue", "green", "red", "dark"]

    var body: some View {
        VStack(spacing: 22) {
            if over {
                GameUI.outcome(status, symbol: "xmark.octagon.fill", tint: Color.signal).gameContent().padding(.top, 20)
            } else {
                Text(status).font(.title3.weight(.semibold)).multilineTextAlignment(.center).gameContent().padding(.top, 20).contentTransition(.numericText())
            }
            HStack(spacing: 28) {
                VStack { Text("\(game.round)").font(.title.weight(.bold)).monospacedDigit(); Text("Round").font(.caption).foregroundStyle(.secondary) }
                VStack { Text("\(best)").font(.title.weight(.bold)).monospacedDigit(); Text("Best").font(.caption).foregroundStyle(.secondary) }
            }
            let cols = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
            LazyVGrid(columns: cols, spacing: 12) {
                ForEach(0..<4, id: \.self) { i in
                    Button { press(i) } label: {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(colors[i].opacity(lit == i ? 1 : 0.35))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(colors[i].opacity(0.6), lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                    .disabled(showing || game.sequence.isEmpty || over)
                    .accessibilityLabel("\(names[i]) pad")
                }
            }
            .gameContent()
            .boardTypeCap()
            .animation(.easeOut(duration: 0.12), value: lit)
            .sensoryFeedback(.impact(weight: .light), trigger: presses)

            GameUI.bigButton(game.sequence.isEmpty || over ? "Start" : "Watching…", symbol: "play.fill") { start() }
                .disabled(!(game.sequence.isEmpty || over))
                .gameContent()
            Spacer()
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Repeat after me")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func start() {
        game.reset(); over = false
        nextRound()
    }

    private func nextRound() {
        game.extend()
        status = "Watch."
        showing = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            for pad in game.sequence {
                lit = pad
                try? await Task.sleep(for: .milliseconds(max(220, 520 - game.round * 20)))
                lit = nil
                try? await Task.sleep(for: .milliseconds(160))
            }
            showing = false
            status = "Your turn. \(game.round) \(game.round == 1 ? "tap" : "taps")."
        }
    }

    private func press(_ i: Int) {
        presses += 1
        lit = i
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150)); if lit == i { lit = nil }
        }
        switch game.press(i) {
        case .more: break
        case .roundDone:
            status = "Round \(game.round) done."
            if game.round > best { best = game.round; UserDefaults.standard.set(best, forKey: "games.simonBest") }
            Task { @MainActor in try? await Task.sleep(for: .milliseconds(700)); nextRound() }
        case .wrong:
            over = true
            status = "Not quite. You made it to round \(game.round)."
        }
    }
}
