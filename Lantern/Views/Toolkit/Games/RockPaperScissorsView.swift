import SwiftUI

struct RockPaperScissorsView: View {
    @State private var mine: RPS?
    @State private var phone: RPS?
    @State private var wins = 0
    @State private var losses = 0
    @State private var ties = 0
    @State private var rounds = 0

    private var outcome: String {
        guard let mine, let phone else { return "Pick one" }
        switch mine.versus(phone) {
        case 1: return "You win"
        case -1: return "Phone wins"
        default: return "Tie"
        }
    }

    var body: some View {
        VStack(spacing: 28) {
            HStack(spacing: 40) {
                hand(mine, label: "You")
                Text("vs").foregroundStyle(.secondary)
                hand(phone, label: "Phone")
            }
            .padding(.top, 30)

            Text(outcome).font(.title.weight(.bold)).contentTransition(.numericText())
                .foregroundStyle(outcome == "You win" ? Color.moss : outcome == "Phone wins" ? Color.signal : Color.primary)

            HStack(spacing: 12) {
                ForEach(RPS.allCases) { choice in
                    Button {
                        mine = choice
                        phone = RPS.allCases.randomElement()!
                        rounds += 1
                        switch choice.versus(phone!) { case 1: wins += 1; case -1: losses += 1; default: ties += 1 }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: choice.symbol).font(.title)
                            Text(choice.rawValue).font(.subheadline)
                        }
                        .frame(maxWidth: .infinity, minHeight: 72)
                    }
                    .buttonStyle(.bordered)
                    .tint(mine == choice ? Color.accentColor : Color.secondary)
                }
            }
            .padding(.horizontal)
            .sensoryFeedback(.impact, trigger: rounds)

            HStack(spacing: 24) {
                stat("Wins", wins); stat("Ties", ties); stat("Losses", losses)
            }
            Button("Reset the score") { wins = 0; losses = 0; ties = 0; mine = nil; phone = nil }
                .font(.footnote).foregroundStyle(.secondary)
            Spacer()
        }
        .navigationTitle("Rock, paper, scissors")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func hand(_ r: RPS?, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: r?.symbol ?? "questionmark").font(.system(size: 48)).frame(height: 60)
                .foregroundStyle(r == nil ? Color.secondary : Color.primary)
                .contentTransition(.symbolEffect(.replace))
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(width: 100)
    }

    private func stat(_ t: String, _ n: Int) -> some View {
        VStack { Text("\(n)").font(.title3.weight(.bold)).monospacedDigit(); Text(t).font(.caption).foregroundStyle(.secondary) }
    }
}
