import SwiftUI

struct GamesView: View {
    @State private var diceCount = 2
    @State private var dice: [Int] = [1, 1]
    @State private var rolls = 0
    @State private var coin: String?
    @State private var flips = 0
    @State private var deck: [String] = GamesView.freshDeck()
    @State private var drawn: [String] = []

    var body: some View {
        List {
            Section("Dice") {
                Stepper("\(diceCount) dice", value: $diceCount, in: 1...6)
                    .onChange(of: diceCount) { _, n in dice = Array(repeating: 1, count: n) }
                HStack(spacing: 12) {
                    ForEach(Array(dice.enumerated()), id: \.offset) { _, d in
                        Image(systemName: "die.face.\(d).fill").font(.system(size: 44)).foregroundStyle(Color.primary)
                            .symbolEffect(.bounce, value: rolls)
                    }
                    Spacer()
                    Text("\(dice.reduce(0, +))").font(.title2.weight(.bold)).monospacedDigit()
                }
                .padding(.vertical, 6)
                Button { dice = (0..<diceCount).map { _ in Int.random(in: 1...6) }; rolls += 1 } label: { Label("Roll", systemImage: "dice") }
                    .sensoryFeedback(.impact(weight: .medium), trigger: rolls)
            }

            Section("Coin") {
                HStack {
                    Text(coin ?? "Tap to flip").font(.title3.weight(.semibold))
                    Spacer()
                    Button { coin = Bool.random() ? "Heads" : "Tails"; flips += 1 } label: { Label("Flip", systemImage: "centsign.circle") }
                        .sensoryFeedback(.impact(weight: .light), trigger: flips)
                }
            }

            Section {
                HStack(spacing: 10) {
                    if drawn.isEmpty { Text("No cards drawn").foregroundStyle(.secondary) }
                    ForEach(Array(drawn.suffix(6).enumerated()), id: \.offset) { _, c in
                        Text(c).font(.title3.weight(.semibold))
                            .padding(.horizontal, 10).padding(.vertical, 8)
                            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(c.hasSuffix("♥") || c.hasSuffix("♦") ? Color.signal : Color.primary)
                    }
                }
                Button { if let c = deck.popLast() { drawn.append(c) } } label: { Label("Draw a card (\(deck.count) left)", systemImage: "rectangle.portrait.on.rectangle.portrait") }
                    .disabled(deck.isEmpty)
                Button { deck = GamesView.freshDeck(); drawn = [] } label: { Label("Shuffle", systemImage: "shuffle") }
            } header: { Text("Cards") } footer: {
                Text("A standard deck. Go Fish, War, Crazy Eights: everyone keeps their hand on their own phone, or just use one and pass it around.")
            }
        }
        .navigationTitle("Pass the time")
        .navigationBarTitleDisplayMode(.inline)
    }

    private static func freshDeck() -> [String] {
        let ranks = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
        let suits = ["♠", "♥", "♦", "♣"]
        return suits.flatMap { s in ranks.map { "\($0)\(s)" } }.shuffled()
    }
}
