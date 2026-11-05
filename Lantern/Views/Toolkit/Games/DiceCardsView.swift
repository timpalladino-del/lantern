import SwiftUI

struct DiceCardsView: View {
    @State private var diceCount = 2
    @State private var dice: [Int] = [1, 1]
    @State private var rolls = 0
    @State private var coin: String?
    @State private var flips = 0
    @State private var deck: [Card] = Card.freshDeck()
    @State private var drawn: [Card] = []
    @State private var hinge = HingeMonitor()

    struct Card: Identifiable, Equatable {
        let rank: String, suit: String
        var id: String { rank + suit }
        var isRed: Bool { suit == "♥" || suit == "♦" }
        var suitName: String { ["♠": "spades", "♥": "hearts", "♦": "diamonds", "♣": "clubs"][suit] ?? suit }
        static func freshDeck() -> [Card] {
            let ranks = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
            return ["♠", "♥", "♦", "♣"].flatMap { s in ranks.map { Card(rank: $0, suit: s) } }.shuffled()
        }
    }

    var body: some View {
        Group {
            if hinge.status == .partiallyOpen { tabletop } else { list }
        }
        .background(HingeObserver(monitor: hinge))
        .navigationTitle("Dice, cards and a coin")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// The iPhone Duo half open on a table: results on the upright half, buttons on the flat half.
    private var tabletop: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                VStack(spacing: 18) {
                    HStack(spacing: 14) {
                        ForEach(Array(dice.enumerated()), id: \.offset) { _, d in
                            Image(systemName: "die.face.\(d).fill").font(.system(size: 64)).symbolEffect(.bounce, value: rolls)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Dice show \(dice.map(String.init).joined(separator: ", ")), total \(dice.reduce(0, +))")
                    Text("\(dice.reduce(0, +))").font(.largeTitle.weight(.bold)).monospacedDigit()
                    if let coin { Text(coin).font(.title2.weight(.semibold)) }
                    if !drawn.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(drawn.suffix(5).reversed()) { c in
                                VStack(spacing: 2) { Text(c.rank).font(.headline); Text(c.suit) }
                                    .frame(width: 46, height: 64)
                                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
                                    .foregroundStyle(c.isRed ? Color.cardRed : Color.primary)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(height: geo.size.height / 2)
                Divider()
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    GameUI.bigButton("Roll", symbol: "dice") { dice = (0..<diceCount).map { _ in Int.random(in: 1...6) }; rolls += 1 }
                    GameUI.bigButton("Flip", symbol: "arrow.trianglehead.2.clockwise.rotate.90", tint: Color.secondary) { coin = Bool.random() ? "Heads" : "Tails"; flips += 1 }
                    GameUI.bigButton("Draw (\(deck.count))", symbol: "rectangle.portrait.on.rectangle.portrait", tint: Color.secondary) { if let c = deck.popLast() { drawn.append(c) } }
                        .disabled(deck.isEmpty)
                    GameUI.bigButton("Shuffle", symbol: "shuffle", tint: Color.secondary) { deck = Card.freshDeck(); drawn = [] }
                    Stepper("\(diceCount) dice", value: $diceCount, in: 1...6)
                        .onChange(of: diceCount) { _, n in dice = Array(repeating: 1, count: n) }
                        .gridCellColumns(2)
                }
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
    }

    private var list: some View {
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
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Dice show \(dice.map(String.init).joined(separator: ", ")), total \(dice.reduce(0, +))")
                Button { dice = (0..<diceCount).map { _ in Int.random(in: 1...6) }; rolls += 1 } label: { Label("Roll", systemImage: "dice") }
                    .sensoryFeedback(.impact(weight: .medium), trigger: rolls)
            }

            Section("Coin") {
                HStack {
                    Image(systemName: coin == nil ? "circle.dashed" : "centsign.circle.fill").font(.title).foregroundStyle(Color.secondary)
                        .symbolEffect(.bounce, value: flips)
                    Text(coin ?? "Tap to flip").font(.title3.weight(.semibold))
                    Spacer()
                    Button { coin = Bool.random() ? "Heads" : "Tails"; flips += 1 } label: { Label("Flip", systemImage: "arrow.trianglehead.2.clockwise.rotate.90") }
                        .sensoryFeedback(.impact(weight: .light), trigger: flips)
                }
            }

            Section {
                if drawn.isEmpty {
                    Text("No cards drawn").foregroundStyle(.secondary)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(drawn.suffix(8).reversed()) { c in
                                VStack(spacing: 2) {
                                    Text(c.rank).font(.title3.weight(.bold))
                                    Text(c.suit).font(.title2)
                                }
                                .frame(width: 54, height: 74)
                                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.secondary.opacity(0.3)))
                                .foregroundStyle(c.isRed ? Color.cardRed : Color.primary)
                                .accessibilityLabel("\(c.rank) of \(c.suitName)")
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                Button { if let c = deck.popLast() { drawn.append(c) } } label: { Label("Draw a card (\(deck.count) left)", systemImage: "rectangle.portrait.on.rectangle.portrait") }
                    .disabled(deck.isEmpty)
                Button { deck = Card.freshDeck(); drawn = [] } label: { Label("Shuffle", systemImage: "shuffle") }
            } header: { Text("Cards") } footer: {
                Text("A standard deck, newest card on the left. Go Fish, War, Crazy Eights: everyone keeps their hand on their own phone, or use one and pass it around.")
            }
        }
    }
}
