import SwiftUI

struct TicTacToeView: View {
    @State private var game = TicTacToe()
    @State private var scoreX = 0, scoreO = 0, draws = 0
    @State private var moves = 0

    private var status: String {
        if let w = game.winner { return "\(w.rawValue) wins" }
        if game.isDraw { return "Draw" }
        return "\(game.turn.rawValue) to play"
    }

    var body: some View {
        VStack(spacing: 24) {
            Text(status).font(.title2.weight(.bold)).padding(.top, 20).contentTransition(.numericText())
            let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
            LazyVGrid(columns: cols, spacing: 8) {
                ForEach(0..<9, id: \.self) { i in
                    Button {
                        if game.play(i) { moves += 1 }
                        if game.winner == .x { scoreX += 1 } else if game.winner == .o { scoreO += 1 } else if game.isDraw { draws += 1 }
                    } label: {
                        Text(game.cells[i]?.rawValue ?? "")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity).aspectRatio(1, contentMode: .fit)
                            .background(cellColor(i), in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(game.cells[i] == .x ? Color.slate : Color.primary)
                    }
                    .buttonStyle(.plain)
                    .disabled(game.cells[i] != nil || game.isOver)
                    .accessibilityLabel(game.cells[i].map { "Cell \(i + 1), \($0.rawValue)" } ?? "Cell \(i + 1), empty")
                }
            }
            .padding(.horizontal, 24)
            .sensoryFeedback(.impact(weight: .light), trigger: moves)

            HStack(spacing: 28) {
                stat("X", scoreX); stat("Draws", draws); stat("O", scoreO)
            }
            GameUI.bigButton(game.isOver ? "Play again" : "Start over", symbol: "arrow.counterclockwise") {
                var next = TicTacToe()
                next.turn = game.winner == .x ? .o : .x   // loser starts; after a draw, O starts
                game = next
            }
            .padding(.horizontal, 24)
            Spacer()
        }
        .navigationTitle("Tic-tac-toe")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func cellColor(_ i: Int) -> Color {
        if let line = game.winningLine, line.contains(i) { return Color.moss.opacity(0.3) }
        return Color(uiColor: .secondarySystemGroupedBackground)
    }

    private func stat(_ t: String, _ n: Int) -> some View {
        VStack { Text("\(n)").font(.title3.weight(.bold)).monospacedDigit(); Text(t).font(.caption).foregroundStyle(.secondary) }
    }
}
