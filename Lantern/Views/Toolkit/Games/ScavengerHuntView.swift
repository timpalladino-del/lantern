import SwiftUI

/// Eight things to find in the house with a flashlight. First one back with all eight wins.
struct ScavengerHuntView: View {
    @State private var items: [String] = Array(GamesLibrary.huntPrompts.shuffled().prefix(8))
    @State private var found: Set<String> = []
    @State private var remaining = 300
    @State private var running = false
    @State private var timeUp = false
    @State private var taps = 0

    var body: some View {
        List {
            Section {
                HStack {
                    Text("\(found.count) of \(items.count) found").font(.headline)
                    Spacer()
                    CountdownTimer(seconds: 300, running: $running, remaining: $remaining) { timeUp = true }
                }
                ProgressView(value: Double(found.count), total: Double(items.count)).tint(Color.glow)
            }
            Section {
                ForEach(items, id: \.self) { item in
                    Button {
                        if found.contains(item) { found.remove(item) } else { found.insert(item) }
                        taps += 1
                        if !running && remaining > 0 { running = true }
                    } label: {
                        HStack {
                            Image(systemName: found.contains(item) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(found.contains(item) ? Color.moss : Color.secondary).font(.title3)
                            Text(item).foregroundStyle(.primary).strikethrough(found.contains(item), color: .secondary)
                        }
                    }
                }
            } header: { Text("Find") } footer: {
                Text("Five minutes on the clock from the first tap. Flashlights on, one room at a time, nobody runs on the stairs. Bring everything back to one spot and show it off.")
            }
            Section {
                GameUI.bigButton(running ? "Pause" : remaining == 0 ? "Time's up" : "Start the clock", symbol: running ? "pause.fill" : "play.fill") { running.toggle() }
                    .disabled(remaining == 0)
                    .listRowBackground(Color.clear).listRowInsets(EdgeInsets())
                Button { newList() } label: { Label("New list", systemImage: "shuffle") }.frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Scavenger hunt")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.selection, trigger: taps)
        .alert("Time's up", isPresented: $timeUp) {
            Button("New list") { newList() }
            Button("Count what we found", role: .cancel) {}
        } message: { Text("\(found.count) of \(items.count). Not bad in the dark.") }
    }

    private func newList() {
        items = Array(GamesLibrary.huntPrompts.shuffled().prefix(8)); found = []; remaining = 300; running = false
    }
}
