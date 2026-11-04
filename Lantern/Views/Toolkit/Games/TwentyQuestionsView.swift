import SwiftUI

/// The phone keeps the secret so nobody has to. Everyone asks yes-or-no questions; the person
/// holding the phone peeks at the answer and replies.
struct TwentyQuestionsView: View {
    @State private var secret = GamesLibrary.secretThings.randomElement()!
    @State private var asked = 0
    @State private var revealed = false
    @State private var peeking = false
    @State private var taps = 0

    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 6) {
                Text("I'm thinking of \(secret.kind).").font(.title3.weight(.semibold))
                Text("Ask yes-or-no questions. The phone holder peeks and answers.").font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            .padding(.horizontal).padding(.top, 24)

            Text(revealed || peeking ? secret.thing : "• • • • •")
                .font(.system(size: 40, weight: .bold, design: .rounded)).minimumScaleFactor(0.5).lineLimit(2)
                .frame(maxWidth: .infinity, minHeight: 110)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal)
                .accessibilityLabel(revealed || peeking ? "The secret is \(secret.thing)" : "Secret hidden")

            Label("Hold to peek", systemImage: "eye.fill")
                .font(.headline).foregroundStyle(revealed ? Color.secondary : Color.accentColor)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.accentColor.opacity(revealed ? 0.06 : 0.12), in: RoundedRectangle(cornerRadius: 10))
                .gesture(DragGesture(minimumDistance: 0).onChanged { _ in if !revealed { peeking = true } }.onEnded { _ in peeking = false })
                .padding(.horizontal)
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Press and hold to see the secret")

            VStack(spacing: 10) {
                Text("\(asked) of 20 questions").font(.headline).contentTransition(.numericText())
                ProgressView(value: Double(asked), total: 20).tint(Color.glow).padding(.horizontal, 40)
                HStack(spacing: 12) {
                    GameUI.bigButton("Asked one", symbol: "plus", tint: Color.accentColor) { if asked < 20 { asked += 1; taps += 1 } }
                        .disabled(asked >= 20 || revealed)
                    GameUI.bigButton(revealed ? "New secret" : "Reveal", symbol: revealed ? "shuffle" : "eye", tint: Color.secondary) {
                        if revealed { secret = GamesLibrary.secretThings.randomElement()!; asked = 0; revealed = false }
                        else { revealed = true }
                    }
                }
                .padding(.horizontal)
            }
            if asked >= 20 && !revealed { Text("That's twenty. Last guess, then reveal.").foregroundStyle(Color.signal).font(.footnote) }
            Spacer()
        }
        .navigationTitle("Twenty questions")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.selection, trigger: taps)
    }
}
