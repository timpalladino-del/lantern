import SwiftUI

/// One person reads the opening line, the next adds a sentence, and so on around the room.
/// When it stalls, a twist.
struct StoryChainView: View {
    @State private var starter = GamesLibrary.storyStarters.randomElement()!
    @State private var twists: [String] = []
    @State private var turns = 0
    @State private var taps = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Once upon a time").font(.caption).textCase(.uppercase).foregroundStyle(.secondary).padding(.top, 12)
                Text(starter).font(.title3.weight(.semibold)).fixedSize(horizontal: false, vertical: true)
                    .padding().frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))

                ForEach(Array(twists.enumerated()), id: \.offset) { i, t in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "sparkles").foregroundStyle(Color.ink).padding(.top, 3)
                            .symbolEffect(.bounce, options: .nonRepeating)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Twist \(i + 1)").font(.caption).foregroundStyle(.secondary)
                            Text(t).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                VStack(spacing: 10) {
                    HStack(spacing: 12) {
                        GameUI.bigButton("Next person", symbol: "person.fill.turn.right") { turns += 1; taps += 1 }
                        GameUI.bigButton("Twist", symbol: "sparkles", tint: Color.secondary) {
                            var t = GamesLibrary.storyTwists.randomElement()!
                            while twists.contains(t) && twists.count < GamesLibrary.storyTwists.count { t = GamesLibrary.storyTwists.randomElement()! }
                            twists.append(t); taps += 1
                        }
                    }
                    Text("\(turns) \(turns == 1 ? "sentence" : "sentences") added so far").font(.footnote).foregroundStyle(.secondary)
                    Button("Start a new story") { starter = GamesLibrary.storyStarters.randomElement()!; twists = []; turns = 0 }
                        .font(.footnote)
                }
                .padding(.top, 8)

                Text("How to play: read the opening line out loud. The next person adds one sentence, then passes the phone. If the story stalls, tap Twist. Finish with \"The end\" from the youngest person.")
                    .font(.footnote).foregroundStyle(.secondary).padding(.top, 12)
            }
            .gameContent()
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Story chain")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.selection, trigger: taps)
    }
}
