import SwiftUI

struct TicTacToeView: View {
    @State private var game = TicTacToe()
    @State private var scoreX = 0
    @State private var scoreO = 0
    @State private var draws = 0
    @State private var moves = 0

    private var status: String {
        if let w = game.winner { return "\(w.rawValue) wins" }
        if game.isDraw { return "Draw" }
        return "\(game.turn.rawValue) to play"
    }

    var body: some View {
        VStack(spacing: 24) {
            if let w = game.winner {
                GameUI.outcome("\(w.rawValue) wins", symbol: "star.fill", tint: Color.moss).padding(.top, 20)
            } else if game.isDraw {
                GameUI.outcome("Draw", symbol: "equal.circle.fill", tint: Color.secondary).padding(.top, 20)
            } else {
                Text(status).font(.title2.weight(.bold)).padding(.top, 20).contentTransition(.numericText())
            }
            let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
            LazyVGrid(columns: cols, spacing: 8) {
                ForEach(0..<9, id: \.self) { i in
                    Button {
                        if game.play(i) { moves += 1 }
                        if game.winner == .x { scoreX += 1 } else if game.winner == .o { scoreO += 1 } else if game.isDraw { draws += 1 }
                    } label: {
                        RoundedRectangle(cornerRadius: 14).fill(cellColor(i))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                Text(game.cells[i]?.rawValue ?? "")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundStyle(game.cells[i] == .x ? Color.ink : Color.primary)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(game.cells[i] != nil || game.isOver)
                    .accessibilityLabel(game.cells[i].map { "Cell \(i + 1), \($0.rawValue)" } ?? "Cell \(i + 1), empty")
                }
            }
            .gameContent()
            .boardTypeCap()
            .sensoryFeedback(.impact(weight: .light), trigger: moves)

            HStack(spacing: 28) {
                stat("X", scoreX); stat("Draws", draws); stat("O", scoreO)
            }
            GameUI.bigButton(game.isOver ? "Play again" : "Start over", symbol: "arrow.counterclockwise") {
                var next = TicTacToe()
                next.turn = game.winner == .x ? .o : .x   // loser starts; after a draw, O starts
                game = next
            }
            .gameContent()
            Spacer()
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
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
