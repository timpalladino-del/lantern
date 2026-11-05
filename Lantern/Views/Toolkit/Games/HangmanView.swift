import SwiftUI

struct HangmanView: View {
    enum Source: String, CaseIterable, Identifiable { case phone = "Phone picks", friend = "A friend types"; var id: String { rawValue } }
    @State private var source: Source = .phone
    @State private var game: Hangman?
    @State private var hint = ""
    @State private var secret = ""
    @State private var guesses = 0
    @FocusState private var secretFocused: Bool

    private let rows = ["ABCDEFG", "HIJKLMN", "OPQRSTU", "VWXYZ"]

    var body: some View {
        VStack(spacing: 20) {
            if let game {
                board(game)
            } else {
                setup
            }
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Hangman")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.impact(weight: .light), trigger: guesses)
    }

    private var setup: some View {
        VStack(spacing: 20) {
            Picker("Who picks", selection: $source) { ForEach(Source.allCases) { Text($0.rawValue).tag($0) } }
                .pickerStyle(.segmented).padding(.horizontal).padding(.top, 20)
            if source == .friend {
                SecureField("Type the secret word, then hand it over", text: $secret)
                    .textFieldStyle(.roundedBorder).textInputAutocapitalization(.characters).autocorrectionDisabled()
                    .focused($secretFocused).padding(.horizontal)
                Text("Letters and spaces only. Nobody else looks.").font(.footnote).foregroundStyle(.secondary)
            } else {
                Text("The phone picks a word from its lists and tells you the category.").font(.footnote).foregroundStyle(.secondary).padding(.horizontal)
            }
            GameUI.bigButton("Start", symbol: "play.fill") { start() }
                .disabled(source == .friend && secret.trimmingCharacters(in: .whitespaces).filter(\.isLetter).isEmpty)
                .gameContent()
            Spacer()
        }
    }

    private func board(_ g: Hangman) -> some View {
        VStack(spacing: 18) {
            gallows(misses: g.misses).frame(height: 150).padding(.top, 10)
            Text(hint).font(.footnote).foregroundStyle(.secondary)
            Text(g.masked).font(.system(.title, design: .monospaced).weight(.bold)).multilineTextAlignment(.center).padding(.horizontal)
                .accessibilityLabel(g.masked.replacingOccurrences(of: "_", with: "blank"))
            if g.isWon {
                GameUI.outcome("You got it.", symbol: "checkmark.seal.fill", tint: Color.moss)
            } else if g.isLost {
                GameUI.outcome("Out of guesses. It was \(g.word).", symbol: "xmark.seal.fill", tint: Color.signal).gameContent()
            } else {
                Text("\(g.missesLeft) wrong \(g.missesLeft == 1 ? "guess" : "guesses") left").font(.headline)
            }
            if g.isOver {
                GameUI.bigButton("Play again", symbol: "arrow.counterclockwise") { game = nil; secret = "" }.gameContent()
            } else {
                VStack(spacing: 8) {
                    ForEach(rows, id: \.self) { row in
                        HStack(spacing: 6) {
                            ForEach(Array(row), id: \.self) { ch in
                                let used = g.guessed.contains(ch)
                                Button {
                                    if game?.guess(ch) == true { guesses += 1 }
                                } label: {
                                    Text(String(ch)).font(.headline).frame(width: 42, height: 42)
                                        .background(used ? Color(uiColor: .tertiarySystemFill) : Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
                                        .foregroundStyle(used ? (g.word.contains(ch) ? Color.moss : Color.secondary.opacity(0.5)) : Color.primary)
                                }
                                .buttonStyle(.plain).disabled(used)
                            }
                        }
                    }
                }
            }
            Spacer()
        }
        .boardTypeCap()
    }

    private func start() {
        if source == .phone {
            let pick = GamesLibrary.hangmanWords.randomElement()!
            game = Hangman(word: pick.word); hint = pick.hint
        } else {
            let w = secret.uppercased().filter { $0.isLetter || $0 == " " }.trimmingCharacters(in: .whitespaces)
            game = Hangman(word: w); hint = "\(w.split(separator: " ").count == 1 ? "One word" : "\(w.split(separator: " ").count) words"), \(w.filter(\.isLetter).count) letters"
        }
        guesses = 0
    }

    /// Drawn with lines so it needs no image. Six parts appear with six misses.
    private func gallows(misses: Int) -> some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let x0 = w / 2 - 60, top = 10.0, ground = h - 6
            var frame = Path()
            frame.move(to: CGPoint(x: x0 - 40, y: ground)); frame.addLine(to: CGPoint(x: x0 + 40, y: ground))
            frame.move(to: CGPoint(x: x0, y: ground)); frame.addLine(to: CGPoint(x: x0, y: top))
            frame.addLine(to: CGPoint(x: x0 + 90, y: top)); frame.addLine(to: CGPoint(x: x0 + 90, y: top + 22))
            ctx.stroke(frame, with: .color(.secondary), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            let cx = x0 + 90, headY = top + 40
            var body = Path()
            if misses >= 1 { body.addEllipse(in: CGRect(x: cx - 16, y: headY - 18, width: 32, height: 32)) }
            if misses >= 2 { body.move(to: CGPoint(x: cx, y: headY + 14)); body.addLine(to: CGPoint(x: cx, y: headY + 60)) }
            if misses >= 3 { body.move(to: CGPoint(x: cx, y: headY + 24)); body.addLine(to: CGPoint(x: cx - 24, y: headY + 46)) }
            if misses >= 4 { body.move(to: CGPoint(x: cx, y: headY + 24)); body.addLine(to: CGPoint(x: cx + 24, y: headY + 46)) }
            if misses >= 5 { body.move(to: CGPoint(x: cx, y: headY + 60)); body.addLine(to: CGPoint(x: cx - 20, y: headY + 92)) }
            if misses >= 6 { body.move(to: CGPoint(x: cx, y: headY + 60)); body.addLine(to: CGPoint(x: cx + 20, y: headY + 92)) }
            ctx.stroke(body, with: .color(.primary), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
        .accessibilityLabel("\(misses) of \(Hangman.maxMisses) wrong guesses")
    }
}
