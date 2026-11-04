import SwiftUI

struct MemoryMatchView: View {
    struct Tile: Identifiable { let id = UUID(); let symbol: String; var faceUp = false; var matched = false }
    private static let symbols = ["sun.max.fill", "moon.fill", "cloud.rain.fill", "leaf.fill", "flame.fill", "drop.fill", "star.fill", "heart.fill",
                                  "bolt.fill", "snowflake", "tortoise.fill", "bird.fill", "fish.fill", "pawprint.fill", "tree.fill", "car.fill"]
    @State private var tiles: [Tile] = MemoryMatchView.deal(pairs: 8)
    @State private var pairs = 8
    @State private var firstIndex: Int?
    @State private var busy = false
    @State private var moves = 0
    @State private var flips = 0

    private var allMatched: Bool { tiles.allSatisfy(\.matched) }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Picker("Size", selection: $pairs) { Text("Easy").tag(6); Text("Medium").tag(8); Text("Hard").tag(12) }
                    .pickerStyle(.segmented).frame(width: 220)
                    .onChange(of: pairs) { _, n in reset(n) }
                Spacer()
                Text("\(moves) moves").font(.headline).monospacedDigit()
            }
            .padding(.horizontal).padding(.top, 12)

            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: pairs == 12 ? 4 : 4)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(tiles.indices, id: \.self) { i in
                    let t = tiles[i]
                    Button { flip(i) } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(t.matched ? Color.moss.opacity(0.25) : t.faceUp ? Color(uiColor: .secondarySystemGroupedBackground) : Color.slate.opacity(0.85))
                            if t.faceUp || t.matched {
                                Image(systemName: t.symbol).font(.title).foregroundStyle(Color.primary)
                            } else {
                                Image(systemName: "flashlight.off.fill").font(.caption).foregroundStyle(Color.white.opacity(0.35))
                            }
                        }
                        .aspectRatio(1, contentMode: .fit)
                        .rotation3DEffect(.degrees(t.faceUp || t.matched ? 0 : 180), axis: (0, 1, 0))
                        .animation(.easeInOut(duration: 0.25), value: t.faceUp)
                    }
                    .buttonStyle(.plain)
                    .disabled(t.faceUp || t.matched || busy)
                    .accessibilityLabel(t.faceUp || t.matched ? "Tile showing \(t.symbol.replacingOccurrences(of: ".fill", with: ""))" : "Face-down tile")
                }
            }
            .padding(.horizontal)
            .sensoryFeedback(.impact(weight: .light), trigger: flips)

            if allMatched {
                Text("All matched in \(moves) moves.").font(.title3.weight(.semibold)).foregroundStyle(Color.moss)
            }
            GameUI.bigButton(allMatched ? "Play again" : "Shuffle", symbol: "shuffle") { reset(pairs) }.padding(.horizontal)
            Spacer()
        }
        .navigationTitle("Memory match")
        .navigationBarTitleDisplayMode(.inline)
    }

    private static func deal(pairs: Int) -> [Tile] {
        let chosen = symbols.shuffled().prefix(pairs)
        return (chosen + chosen).shuffled().map { Tile(symbol: $0) }
    }

    private func reset(_ n: Int) { tiles = MemoryMatchView.deal(pairs: n); firstIndex = nil; moves = 0; busy = false }

    private func flip(_ i: Int) {
        tiles[i].faceUp = true; flips += 1
        guard let f = firstIndex else { firstIndex = i; return }
        moves += 1
        firstIndex = nil
        if tiles[f].symbol == tiles[i].symbol {
            tiles[f].matched = true; tiles[i].matched = true
        } else {
            busy = true
            Task {
                try? await Task.sleep(for: .milliseconds(800))
                tiles[f].faceUp = false; tiles[i].faceUp = false; busy = false
            }
        }
    }
}
