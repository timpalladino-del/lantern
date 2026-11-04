import SwiftUI

/// The hub for the long evening. Everything works with no signal, on one phone passed around.
struct GamesView: View {
    var body: some View {
        List {
            Section {
                row("Dice, cards and a coin", "dice.fill") { DiceCardsView() }
                row("Rock, paper, scissors", "scissors") { RockPaperScissorsView() }
                row("Who goes first?", "person.2.wave.2.fill") { WhoGoesFirstView() }
            } header: { Text("Quick") } footer: {
                Text("Settle an argument, pick a team, start a board game you already own.")
            }

            Section("One phone, two players") {
                row("Tic-tac-toe", "number", "Pass the phone.") { TicTacToeView() }
                row("Four in a row", "circle.grid.3x3.fill", "Drop pieces, connect four.") { FourInARowView() }
                row("Hangman", "textformat.abc", "One picks, one guesses.") { HangmanView() }
                row("Draw and guess", "pencil.and.scribble", "Draw the word, no talking.") { DrawGuessView() }
            }

            Section("Everyone") {
                row("Heads up", "person.crop.rectangle.fill", "Hold the phone to your forehead. They give clues, you guess.") { WordRoundView(mode: .headsUp) }
                row("Act it out", "theatermasks.fill", "Charades with a timer and a word list.") { WordRoundView(mode: .actItOut) }
                row("Would you rather", "arrow.left.arrow.right", "Vote, argue, next.") { WouldYouRatherView() }
                row("Twenty questions", "questionmark.circle.fill", "The phone has a secret. Yes or no only.") { TwentyQuestionsView() }
                row("Trivia", "lightbulb.fill", "Ten questions, half of them about being ready.") { TriviaView() }
                row("Story chain", "book.pages.fill", "One sentence each, with a twist when it stalls.") { StoryChainView() }
                row("Flashlight scavenger hunt", "flashlight.on.fill", "Find eight things in the dark.") { ScavengerHuntView() }
                row("Shadow puppets", "hand.raised.fingers.spread.fill", "A flashlight, a wall, your hands.") { ShadowPuppetsView() }
            }

            Section {
                row("Memory match", "square.grid.4x3.fill", "Find the pairs.") { MemoryMatchView() }
                row("Repeat after me", "waveform.path", "Watch the pattern, tap it back.") { SimonView() }
                row("Guess my number", "number.circle.fill", "One to a hundred, higher or lower.") { NumberGuessView() }
            } header: { Text("Just you") } footer: {
                Text("Every game here is on the phone. No signal, no account, no ads, and nothing is recorded.")
            }
        }
        .navigationTitle("Pass the time")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row<D: View>(_ title: String, _ symbol: String, _ subtitle: String? = nil, @ViewBuilder destination: @escaping () -> D) -> some View {
        NavigationLink { destination() } label: {
            HStack(spacing: 12) {
                Image(systemName: symbol).frame(width: 28).foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                    if let subtitle { Text(subtitle).font(.footnote).foregroundStyle(.secondary) }
                }
            }
        }
    }
}

/// Shared pieces for the game screens.
enum GameUI {
    /// A big neutral action button that fills the row.
    static func bigButton(_ title: String, symbol: String, tint: Color = .accentColor, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol).font(.headline).frame(maxWidth: .infinity, minHeight: 50)
        }
        .buttonStyle(.borderedProminent)
        .tint(tint)
    }
}

/// Counts down and stops at zero. Kept small so every timed game shares one.
struct CountdownTimer: View {
    let seconds: Int
    @Binding var running: Bool
    @Binding var remaining: Int
    var onEnd: () -> Void
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "timer")
            Text(String(format: "%d:%02d", remaining / 60, remaining % 60)).monospacedDigit()
        }
        .font(.headline)
        .foregroundStyle(remaining <= 10 && running ? Color.signal : Color.primary)
        .onReceive(tick) { _ in
            guard running else { return }
            if remaining > 0 { remaining -= 1 }
            if remaining == 0 { running = false; onEnd() }
        }
    }
}
