import SwiftUI
import SwiftData

/// Spins through the names in the house and lands on one. Also splits teams.
struct WhoGoesFirstView: View {
    @Query private var people: [Person]
    @State private var names: [String] = []
    @State private var newName = ""
    @State private var highlighted: Int?
    @State private var winner: String?
    @State private var spinning = false
    @State private var teams: [[String]] = []
    @State private var spins = 0

    var body: some View {
        List {
            Section {
                ForEach(Array(names.enumerated()), id: \.offset) { i, n in
                    HStack {
                        Text(n).font(highlighted == i ? .headline : .body)
                        Spacer()
                        if winner == n { Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.moss).symbolEffect(.bounce, options: .nonRepeating) }
                        else if highlighted == i { Image(systemName: "circle.fill").foregroundStyle(Color.ink).font(.caption) }
                    }
                    .listRowBackground(highlighted == i ? Color.glow.opacity(0.15) : nil)
                }
                .onDelete { if !spinning { names.remove(atOffsets: $0); winner = nil; teams = [] } }
                .deleteDisabled(spinning)
                HStack {
                    TextField("Add a name", text: $newName).submitLabel(.done).onSubmit(add)
                    Button("Add", action: add).disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            } header: { Text("Players") } footer: {
                Text("Your household is filled in. Add guests, swipe to remove anyone sitting this one out.")
            }

            Section {
                GameUI.bigButton(spinning ? "Spinning" : "Spin", symbol: "arrow.trianglehead.2.clockwise.rotate.90") { spin() }
                    .disabled(names.count < 2 || spinning)
                    .listRowBackground(Color.clear).listRowInsets(EdgeInsets())
                if let winner { GameUI.outcome("\(winner) goes first.", symbol: "flag.checkered", tint: Color.primary).frame(maxWidth: .infinity) }
            }

            Section {
                Button { makeTeams() } label: { Label("Split into two teams", systemImage: "person.2.fill") }
                    .disabled(names.count < 2)
                ForEach(Array(teams.enumerated()), id: \.offset) { i, t in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Team \(i + 1)").font(.caption).foregroundStyle(.secondary)
                        Text(t.joined(separator: ", "))
                    }
                }
            }
        }
        .navigationTitle("Who goes first?")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.success, trigger: spins)
        .onAppear { if names.isEmpty { names = people.map(\.name).filter { !$0.isEmpty } } }
    }

    private func add() {
        let n = newName.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty else { return }
        names.append(n); newName = ""; winner = nil; teams = []
    }

    private func spin() {
        guard names.count >= 2 else { return }
        spinning = true; winner = nil
        let target = Int.random(in: 0..<names.count)
        let steps = names.count * 3 + target
        Task { @MainActor in
            for s in 0...steps {
                highlighted = s % names.count
                let delay = 60 + (s * s * 400) / max(1, steps * steps)   // slows down toward the end
                try? await Task.sleep(for: .milliseconds(delay))
            }
            guard target < names.count else { spinning = false; return }
            highlighted = target
            winner = names[target]
            spins += 1
            spinning = false
        }
    }

    private func makeTeams() {
        let s = names.shuffled()
        let half = (s.count + 1) / 2
        teams = [Array(s.prefix(half)), Array(s.dropFirst(half))]
    }
}
