import SwiftUI

struct NumberGuessView: View {
    @State private var game = NumberGuess()
    @State private var entry = ""
    @State private var hint = "I'm thinking of a number from 1 to 100."
    @State private var best: Int? = UserDefaults.standard.object(forKey: "games.numberBest") as? Int
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 24) {
            Text(hint).font(.title3.weight(.semibold)).multilineTextAlignment(.center).padding(.horizontal).padding(.top, 30)
                .contentTransition(.numericText())
            HStack {
                TextField("Your guess", text: $entry).keyboardType(.numberPad).textFieldStyle(.roundedBorder).focused($focused)
                    .font(.title2).frame(width: 140).multilineTextAlignment(.center).submitLabel(.go).onSubmit(submit)
                    .disabled(game.isWon)
                Button("Guess", action: submit).buttonStyle(.borderedProminent).disabled(game.isWon || Int(entry) == nil)
            }
            if !game.guesses.isEmpty {
                Text("Guesses: " + game.guesses.map(String.init).joined(separator: ", ")).font(.footnote).foregroundStyle(.secondary).padding(.horizontal)
            }
            if game.isWon {
                GameUI.bigButton("Play again", symbol: "arrow.counterclockwise") { game = NumberGuess(); entry = ""; hint = "New number. 1 to 100."; focused = true }
                    .padding(.horizontal)
            }
            if let best { Text("Fewest guesses so far: \(best)").font(.caption).foregroundStyle(.secondary) }
            Spacer()
        }
        .navigationTitle("Guess my number")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { focused = true }
    }

    private func submit() {
        guard let n = Int(entry), (1...100).contains(n) else { hint = "Pick a whole number from 1 to 100."; return }
        switch game.guess(n) {
        case .low: hint = "\(n) is too low. Higher."
        case .high: hint = "\(n) is too high. Lower."
        case .right:
            let c = game.guesses.count
            hint = "\(n). Got it in \(c) \(c == 1 ? "guess" : "guesses")."
            if best == nil || c < best! { best = c; UserDefaults.standard.set(c, forKey: "games.numberBest") }
        }
        entry = ""
    }
}
