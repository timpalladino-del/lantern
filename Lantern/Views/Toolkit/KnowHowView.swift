import SwiftUI

struct KnowHowView: View {
    private let library = KnowHowLibrary.shared

    var body: some View {
        List {
            ForEach(library.categories, id: \.self) { category in
                Section(category) {
                    ForEach(library.cards(in: category)) { card in
                        NavigationLink { KnowHowCardView(card: card) } label: {
                            HStack(spacing: 12) {
                                Image(systemName: card.symbol).frame(width: 28).foregroundStyle(Color.glow)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(card.title)
                                    Text(card.summary).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            Section { Text(library.disclaimer).font(.footnote).foregroundStyle(.secondary) }
        }
        .navigationTitle("Know-how")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct KnowHowCardView: View {
    let card: KnowHowCard
    private let library = KnowHowLibrary.shared

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: card.symbol).font(.title2).foregroundStyle(Color.glow)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(card.title).font(.title3.weight(.semibold))
                        Text(card.summary).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            Section("Steps") {
                ForEach(Array(card.steps.enumerated()), id: \.offset) { i, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(i + 1)").font(.subheadline.weight(.bold)).monospacedDigit().foregroundStyle(Color.glow).frame(width: 22, alignment: .trailing)
                        Text(step)
                    }
                    .padding(.vertical, 2)
                }
            }
            Section {
                if let s = card.sourceURL, let url = URL(string: s) {
                    Link(destination: url) { Label(card.source, systemImage: "link") }
                } else {
                    Text(card.source)
                }
                Text(library.disclaimer).font(.footnote).foregroundStyle(.secondary)
            } header: { Text("Source") }
        }
        .navigationTitle(card.category)
        .navigationBarTitleDisplayMode(.inline)
    }
}
