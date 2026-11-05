import SwiftUI

struct WouldYouRatherView: View {
    @State private var order: [Int] = Array(GamesLibrary.wouldYouRather.indices).shuffled()
    @State private var index = 0
    @State private var votesA = 0
    @State private var votesB = 0
    @State private var taps = 0

    private var pair: (String, String) { GamesLibrary.wouldYouRather[order[index]] }

    var body: some View {
        VStack(spacing: 20) {
            Text("Would you rather…").font(.title2.weight(.semibold)).padding(.top, 24)
            choice(pair.0, votes: votesA, tint: Color.accentColor) { votesA += 1; taps += 1 }
            Text("or").foregroundStyle(.secondary)
            choice(pair.1, votes: votesB, tint: Color.moss) { votesB += 1; taps += 1 }
            Spacer()
            Text("\(index + 1) of \(order.count)").font(.caption).foregroundStyle(.secondary)
            GameUI.bigButton("Next", symbol: "arrow.right") {
                index = (index + 1) % order.count
                if index == 0 { order.shuffle() }
                votesA = 0; votesB = 0
            }
            .gameContent().padding(.bottom, 8)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Would you rather")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.selection, trigger: taps)
    }

    private func choice(_ text: String, votes: Int, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(text).font(.title3.weight(.semibold)).multilineTextAlignment(.center).foregroundStyle(.primary)
                Label(votes == 0 ? "Tap to vote" : "\(votes) \(votes == 1 ? "vote" : "votes")", systemImage: votes == 0 ? "hand.tap" : "hand.thumbsup.fill")
                    .font(.footnote).foregroundStyle(.secondary).contentTransition(.numericText())
                    .symbolEffect(.bounce, value: votes)
            }
            .frame(maxWidth: .infinity, minHeight: 120).padding()
            .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(tint.opacity(0.5)))
        }
        .buttonStyle(.plain)
        .gameContent()
    }
}
