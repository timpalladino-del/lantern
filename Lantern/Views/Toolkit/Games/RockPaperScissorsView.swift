import SwiftUI

struct RockPaperScissorsView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var headToHead = false
    @State private var mine: RPS?
    @State private var phone: RPS?
    @State private var wins = 0
    @State private var losses = 0
    @State private var ties = 0
    @State private var rounds = 0

    private var outcome: String {
        guard let mine, let phone else { return "Pick one" }
        switch mine.versus(phone) {
        case 1: return "You win"
        case -1: return "Phone wins"
        default: return "Tie"
        }
    }

    var body: some View {
        Group {
            if headToHead { HeadToHeadRPS() } else { solo }
        }
        .toolbar {
            // Side by side on the open Duo or an iPad: one player on each half of the screen.
            if sizeClass == .regular {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("Mode", selection: $headToHead) {
                        Text("Phone").tag(false)
                        Text("Two players").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .navigationTitle("Rock, paper, scissors")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var solo: some View {
        VStack(spacing: 28) {
            HStack(spacing: 40) {
                hand(mine, label: "You")
                Text("vs").foregroundStyle(.secondary)
                hand(phone, label: "Phone")
            }
            .padding(.top, 30)

            Label(outcome, systemImage: mine == nil ? "hand.tap" : outcome == "You win" ? "star.fill" : outcome == "Tie" ? "equal.circle" : "xmark.circle")
                .font(.title.weight(.bold)).contentTransition(.numericText())
                .symbolEffect(.bounce, value: rounds)
                .foregroundStyle(outcome == "You win" ? Color.moss : outcome == "Phone wins" ? Color.signal : Color.primary)

            HStack(spacing: 12) {
                ForEach(RPS.allCases) { choice in
                    Button {
                        mine = choice
                        phone = RPS.allCases.randomElement()!
                        rounds += 1
                        switch choice.versus(phone!) { case 1: wins += 1; case -1: losses += 1; default: ties += 1 }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: choice.symbol).font(.title)
                            Text(choice.rawValue).font(.subheadline)
                        }
                        .frame(maxWidth: .infinity, minHeight: 72)
                    }
                    .buttonStyle(.bordered)
                    .tint(mine == choice ? Color.accentColor : Color.secondary)
                }
            }
            .gameContent()
            .sensoryFeedback(.impact, trigger: rounds)

            HStack(spacing: 24) {
                stat("Wins", wins); stat("Ties", ties); stat("Losses", losses)
            }
            Button("Reset the score") { wins = 0; losses = 0; ties = 0; mine = nil; phone = nil }
                .font(.footnote).foregroundStyle(.secondary)
            Spacer()
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
    }

    private func hand(_ r: RPS?, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: r?.symbol ?? "questionmark").font(.system(size: 48)).frame(height: 60)
                .foregroundStyle(r == nil ? Color.secondary : Color.primary)
                .contentTransition(.symbolEffect(.replace))
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(width: 100)
    }

    private func stat(_ t: String, _ n: Int) -> some View {
        VStack { Text("\(n)").font(.title3.weight(.bold)).monospacedDigit(); Text(t).font(.caption).foregroundStyle(.secondary) }
    }
}

/// Two people, one open phone. The top half is turned to face the person across the hinge.
/// Each picks on their own half; nothing shows until both have picked.
struct HeadToHeadRPS: View {
    @State private var top: RPS?
    @State private var bottom: RPS?
    @State private var topWins = 0
    @State private var bottomWins = 0
    @State private var rounds = 0

    private var revealed: Bool { top != nil && bottom != nil }

    var body: some View {
        VStack(spacing: 0) {
            half(mine: $top, theirs: bottom, wins: topWins, label: "Player 2")
                .rotationEffect(.degrees(180))
            Divider().overlay(Color.secondary.opacity(0.4))
            half(mine: $bottom, theirs: top, wins: bottomWins, label: "Player 1")
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .sensoryFeedback(.success, trigger: rounds)
        .onChange(of: revealed) { _, now in
            guard now, let t = top, let b = bottom else { return }
            switch t.versus(b) { case 1: topWins += 1; case -1: bottomWins += 1; default: break }
            rounds += 1
        }
    }

    private func half(mine: Binding<RPS?>, theirs: RPS?, wins: Int, label: String) -> some View {
        VStack(spacing: 14) {
            HStack {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text("\(wins) won").font(.caption).foregroundStyle(.secondary).monospacedDigit()
            }
            .padding(.horizontal)
            Spacer(minLength: 0)
            if revealed, let m = mine.wrappedValue, let t = theirs {
                HStack(spacing: 28) {
                    VStack(spacing: 4) { Image(systemName: m.symbol).font(.system(size: 40)); Text("You").font(.caption).foregroundStyle(.secondary) }
                    Text("vs").foregroundStyle(.secondary)
                    VStack(spacing: 4) { Image(systemName: t.symbol).font(.system(size: 40)); Text("Them").font(.caption).foregroundStyle(.secondary) }
                }
                Text(m.versus(t) == 1 ? "You win" : m.versus(t) == -1 ? "They win" : "Tie")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(m.versus(t) == 1 ? Color.moss : m.versus(t) == -1 ? Color.signal : Color.primary)
                Button("Again") { top = nil; bottom = nil }.buttonStyle(.borderedProminent)
            } else if mine.wrappedValue != nil {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 36)).foregroundStyle(Color.moss).symbolEffect(.bounce, options: .nonRepeating)
                Text("Picked. Waiting for the other side.").foregroundStyle(.secondary)
            } else {
                Text("Pick one").font(.title3.weight(.semibold))
                HStack(spacing: 12) {
                    ForEach(RPS.allCases) { choice in
                        Button { mine.wrappedValue = choice } label: {
                            VStack(spacing: 6) {
                                Image(systemName: choice.symbol).font(.title)
                                Text(choice.rawValue).font(.subheadline)
                            }
                            .frame(maxWidth: .infinity, minHeight: 72)
                        }
                        .buttonStyle(.bordered)
                        .tint(Color.secondary)
                    }
                }
                .gameContent()
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 12)
    }
}
