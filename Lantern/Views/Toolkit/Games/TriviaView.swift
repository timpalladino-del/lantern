import SwiftUI

struct TriviaView: View {
    @State private var round: [GamesLibrary.Question] = GamesLibrary.quizRound()
    @State private var index = 0
    @State private var picked: Int?
    @State private var score = 0
    @State private var done = false
    @State private var taps = 0
    @State private var best: Int = UserDefaults.standard.integer(forKey: "games.triviaBest")

    private var q: GamesLibrary.Question { round[index] }

    var body: some View {
        Group {
            if done { summary } else { question }
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Trivia")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.impact(weight: .light), trigger: taps)
    }

    private var question: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Question \(index + 1) of \(round.count)").font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                if q.readiness { Label("Readiness", systemImage: "flashlight.on.fill").font(.caption).foregroundStyle(Color.glow) }
                Text("\(score)").font(.headline).monospacedDigit()
            }
            Text(q.prompt).font(.title3.weight(.semibold)).fixedSize(horizontal: false, vertical: true)
            ForEach(Array(q.options.enumerated()), id: \.offset) { i, opt in
                Button {
                    guard picked == nil else { return }
                    picked = i; taps += 1
                    if i == q.answer { score += 1 }
                } label: {
                    HStack {
                        Text(opt).multilineTextAlignment(.leading).foregroundStyle(.primary)
                        Spacer()
                        if picked != nil && i == q.answer { Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.moss).symbolEffect(.bounce, options: .nonRepeating) }
                        else if picked == i { Image(systemName: "xmark.circle.fill").foregroundStyle(Color.signal).symbolEffect(.bounce, options: .nonRepeating) }
                    }
                    .padding(.horizontal, 14).frame(maxWidth: .infinity, minHeight: 50)
                    .background(background(i), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(picked != nil)
            }
            if picked != nil {
                Text(q.note).font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true).padding(.top, 4)
                GameUI.bigButton(index + 1 == round.count ? "See the score" : "Next", symbol: "arrow.right") {
                    if index + 1 == round.count { done = true; if score > best { best = score; UserDefaults.standard.set(score, forKey: "games.triviaBest") } }
                    else { index += 1; picked = nil }
                }
            }
            Spacer()
        }
        .padding(.vertical, GameUI.margin)
        .gameContent()
    }

    private func background(_ i: Int) -> Color {
        guard let picked else { return Color(uiColor: .secondarySystemGroupedBackground) }
        if i == q.answer { return Color.moss.opacity(0.2) }
        if i == picked { return Color.signal.opacity(0.15) }
        return Color(uiColor: .secondarySystemGroupedBackground)
    }

    private var summary: some View {
        VStack(spacing: 18) {
            Image(systemName: score == round.count ? "trophy.fill" : "lightbulb.max.fill").font(.system(size: 44)).foregroundStyle(Color.glow)
                .symbolEffect(.bounce, options: .nonRepeating).padding(.top, 32).accessibilityHidden(true)
            Text("\(score) of \(round.count)").font(.system(size: 64, weight: .bold, design: .rounded))
            Text(score == round.count ? "Perfect. You're the one to call in a storm." : score >= round.count * 7 / 10 ? "Good. The house is in safe hands." : "The know-how cards cover every readiness answer here.")
                .multilineTextAlignment(.center).foregroundStyle(.secondary).gameContent()
            Text("Best so far: \(best)").font(.caption).foregroundStyle(.secondary)
            GameUI.bigButton("Another round", symbol: "arrow.counterclockwise") {
                round = GamesLibrary.quizRound(); index = 0; picked = nil; score = 0; done = false
            }
            .gameContent()
            Spacer()
        }
    }
}
