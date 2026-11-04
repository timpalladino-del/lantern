import SwiftUI

struct FourInARowView: View {
    @State private var game = FourInARow()
    @State private var scoreA = 0, scoreB = 0
    @State private var drops = 0

    private var status: String {
        if let w = game.winner { return w == .a ? "Blue wins" : "Green wins" }
        if game.isFull { return "Board full. Draw." }
        return game.turn == .a ? "Blue to drop" : "Green to drop"
    }

    private func color(_ p: FourInARow.Piece?) -> Color {
        switch p { case .a: return Color.slate; case .b: return Color.moss; case nil: return Color(uiColor: .tertiarySystemFill) }
    }

    var body: some View {
        VStack(spacing: 18) {
            Text(status).font(.title2.weight(.bold)).padding(.top, 20).contentTransition(.numericText())

            GeometryReader { geo in
                let cell = min(geo.size.width / CGFloat(FourInARow.columns), geo.size.height / CGFloat(FourInARow.rows + 1))
                let winning = game.winningCells?.cells ?? []
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        ForEach(0..<FourInARow.columns, id: \.self) { c in
                            Button {
                                if game.drop(c) { drops += 1 }
                                if game.winner == .a { scoreA += 1 } else if game.winner == .b { scoreB += 1 }
                            } label: {
                                Image(systemName: "arrowtriangle.down.fill").font(.caption)
                                    .foregroundStyle(game.canDrop(c) ? color(game.turn) : Color.clear)
                                    .frame(width: cell, height: cell * 0.7)
                            }
                            .disabled(!game.canDrop(c))
                            .accessibilityLabel("Drop in column \(c + 1)")
                        }
                    }
                    ForEach((0..<FourInARow.rows).reversed(), id: \.self) { r in
                        HStack(spacing: 0) {
                            ForEach(0..<FourInARow.columns, id: \.self) { c in
                                Circle().fill(color(game.grid[c][r]))
                                    .overlay(Circle().strokeBorder(Color.glow, lineWidth: winning.contains { $0 == (c, r) } ? 3 : 0))
                                    .padding(3).frame(width: cell, height: cell)
                            }
                        }
                    }
                }
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                .frame(maxWidth: .infinity)
            }
            .frame(height: 360)
            .padding(.horizontal, 16)
            .sensoryFeedback(.impact(weight: .medium), trigger: drops)

            HStack(spacing: 28) {
                stat("Blue", scoreA, Color.slate); stat("Green", scoreB, Color.moss)
            }
            GameUI.bigButton(game.winner != nil || game.isFull ? "Play again" : "Start over", symbol: "arrow.counterclockwise") {
                var next = FourInARow()
                next.turn = game.winner == .a ? .b : .a
                game = next
            }
            .padding(.horizontal, 24)
            Spacer()
        }
        .navigationTitle("Four in a row")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func stat(_ t: String, _ n: Int, _ c: Color) -> some View {
        HStack(spacing: 8) { Circle().fill(c).frame(width: 14, height: 14); Text("\(n)").font(.title3.weight(.bold)).monospacedDigit(); Text(t).font(.caption).foregroundStyle(.secondary) }
    }
}
