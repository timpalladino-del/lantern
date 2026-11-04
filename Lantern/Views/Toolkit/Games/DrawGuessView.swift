import SwiftUI

/// One person draws the secret word with a finger, everyone else guesses. No talking from the artist.
struct DrawGuessView: View {
    struct Stroke: Identifiable { let id = UUID(); var points: [CGPoint]; let width: CGFloat }
    @State private var strokes: [Stroke] = []
    @State private var current: Stroke?
    @State private var word: String = GamesLibrary.categories.flatMap(\.words).randomElement()!
    @State private var wordShown = false
    @State private var brush: CGFloat = 5
    @State private var remaining = 90
    @State private var running = false
    @State private var timeUp = false

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    wordShown.toggle()
                } label: {
                    Label(wordShown ? word : "Show the artist the word", systemImage: wordShown ? "eye.fill" : "eye.slash")
                        .font(.headline).lineLimit(1)
                }
                .buttonStyle(.bordered)
                Spacer()
                CountdownTimer(seconds: 90, running: $running, remaining: $remaining) { timeUp = true }
            }
            .padding(.horizontal)

            Canvas { ctx, _ in
                for s in strokes + (current.map { [$0] } ?? []) {
                    var p = Path()
                    if s.points.count == 1 { p.addEllipse(in: CGRect(x: s.points[0].x - s.width / 2, y: s.points[0].y - s.width / 2, width: s.width, height: s.width)) }
                    else { p.addLines(s.points) }
                    ctx.stroke(p, with: .color(.primary), style: StrokeStyle(lineWidth: s.width, lineCap: .round, lineJoin: .round))
                }
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.secondary.opacity(0.25)))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        if !running && !timeUp { running = true }
                        if current == nil { current = Stroke(points: [v.location], width: brush) } else { current?.points.append(v.location) }
                    }
                    .onEnded { _ in if let c = current { strokes.append(c) }; current = nil }
            )
            .padding(.horizontal)
            .accessibilityLabel("Drawing area")

            HStack(spacing: 14) {
                Picker("Brush", selection: $brush) {
                    Image(systemName: "circle.fill").font(.system(size: 8)).tag(CGFloat(3))
                    Image(systemName: "circle.fill").font(.system(size: 13)).tag(CGFloat(6))
                    Image(systemName: "circle.fill").font(.system(size: 20)).tag(CGFloat(12))
                }
                .pickerStyle(.segmented).frame(width: 150)
                Button { _ = strokes.popLast() } label: { Label("Undo", systemImage: "arrow.uturn.backward") }.disabled(strokes.isEmpty)
                Button { strokes = [] } label: { Label("Clear", systemImage: "trash") }.disabled(strokes.isEmpty)
            }
            .labelStyle(.iconOnly).font(.title3)
            .padding(.horizontal)

            HStack(spacing: 12) {
                GameUI.bigButton("They got it", symbol: "checkmark", tint: Color.moss) { next() }
                GameUI.bigButton("New word", symbol: "shuffle", tint: Color.secondary) { next() }
            }
            .padding(.horizontal).padding(.bottom, 8)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Draw and guess")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Time's up", isPresented: $timeUp) {
            Button("Next word") { next() }
            Button("Keep drawing", role: .cancel) { remaining = 30; running = true }
        } message: { Text("The word was \(word).") }
    }

    private func next() {
        word = GamesLibrary.categories.flatMap(\.words).randomElement()!
        strokes = []; current = nil; wordShown = false; remaining = 90; running = false; timeUp = false
    }
}
