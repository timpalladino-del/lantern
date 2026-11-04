import SwiftUI

struct ShadowPuppetsView: View {
    var body: some View {
        List {
            Section {
                Text("Put the flashlight on a table a few feet from a bare wall, or use Lantern's screen flashlight. Sit between them. The closer your hands are to the light, the bigger the puppet.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            ForEach(GamesLibrary.puppets) { p in
                Section {
                    ForEach(Array(p.steps.enumerated()), id: \.offset) { i, s in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(i + 1)").font(.caption.weight(.bold)).frame(width: 20, height: 20)
                                .background(Color(uiColor: .tertiarySystemFill), in: Circle())
                            Text(s).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                } header: { Label(p.name, systemImage: p.symbol) }
            }
            Section {
                NavigationLink { LightToolsView() } label: { Label("Open the flashlight", systemImage: "flashlight.on.fill") }
            } footer: {
                Text("Make up a story with two puppets and let the kids guess who is talking.")
            }
        }
        .navigationTitle("Shadow puppets")
        .navigationBarTitleDisplayMode(.inline)
    }
}
