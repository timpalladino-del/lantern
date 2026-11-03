import SwiftUI
import SwiftData
import UIKit

struct SignalsView: View {
    @Environment(\.modelContext) private var context
    @Query private var plans: [HouseholdPlan]
    private let library = KnowHowLibrary.shared

    var body: some View {
        List {
            Section {
                Text("Wireless Emergency Alerts reach your phone with no app and no account, as long as a tower is up. Keep them on.")
                    .font(.subheadline)
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                } label: { Label("Open Settings", systemImage: "gear") }
                Text("In Settings, go to Notifications and scroll to the bottom for Government Alerts.").font(.footnote).foregroundStyle(.secondary)
            } header: { Text("Phone alerts") }

            Section {
                ForEach(RadioReference.noaaFrequencies, id: \.self) { f in
                    HStack {
                        Text("\(f) MHz").monospacedDigit()
                        Spacer()
                        if let p = plans.first, p.noaaStation.contains(f) { Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.moss) }
                    }
                }
                if let p = plans.first {
                    TextField("My station (e.g. 162.550, KHB-35, county code 012009)", text: Binding(get: { p.noaaStation }, set: { p.noaaStation = $0; try? context.save() }), axis: .vertical)
                }
            } header: { Text("NOAA Weather Radio") } footer: {
                Text(RadioReference.noaaNote)
            }

            Section {
                if let sos = library.card("sos_satellite") {
                    NavigationLink { KnowHowCardView(card: sos) } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Label("Emergency SOS via satellite", systemImage: "sos")
                            Text("iPhone 14 and later can reach 911 with no signal. Try the demo before you need it.").font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                }
                if let alerts = library.card("alerts") {
                    NavigationLink { KnowHowCardView(card: alerts) } label: { Label("Getting warnings when the power is out", systemImage: "exclamationmark.triangle.fill") }
                }
            } header: { Text("No signal") } footer: {
                Text("Lantern does not duplicate Emergency SOS. Apple's built-in version is better than anything an app can do.")
            }
        }
        .navigationTitle("Alerts and signals")
        .navigationBarTitleDisplayMode(.inline)
    }
}
