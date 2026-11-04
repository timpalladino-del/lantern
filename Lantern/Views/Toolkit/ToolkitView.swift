import SwiftUI
import SwiftData

/// Everything the phone can do for you when the lights are out. All of it works with no signal.
struct ToolkitView: View {
    @Query(sort: \OutageEvent.startedAt, order: .reverse) private var outages: [OutageEvent]

    private var activeOutage: OutageEvent? { outages.first { $0.isActive } }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink { OutageView() } label: {
                        HStack(spacing: 14) {
                            Image(systemName: activeOutage == nil ? "powerplug" : "powerplug.fill")
                                .font(.title2)
                                .foregroundStyle(activeOutage == nil ? Color.secondary : Color.ember)
                                .frame(width: 36)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(activeOutage == nil ? "Outage mode" : "Power is out")
                                    .font(.headline)
                                Text(activeOutage.map { "Since \($0.startedAt.formatted(date: .omitted, time: .shortened)). Fridge and freezer clocks running." }
                                     ?? "Start the clocks when the power goes out. Fridge, freezer, generator, battery.")
                                    .font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Light") {
                    NavigationLink { LightToolsView() } label: {
                        Label("SOS strobe and flashlight", systemImage: "flashlight.on.fill")
                    }
                }

                Section("Sound") {
                    NavigationLink { SoundToolsView() } label: {
                        Label("Alarm whistle and sleep sounds", systemImage: "speaker.wave.3.fill")
                    }
                }

                Section("Information, no signal needed") {
                    NavigationLink { ContactsView() } label: { Label("Emergency numbers and contacts", systemImage: "phone.fill") }
                    NavigationLink { MedicationCardView() } label: { Label("Medication card", systemImage: "pills.fill") }
                    NavigationLink { PlanView() } label: { Label("Our plan: meeting spots and shutoffs", systemImage: "map.fill") }
                    NavigationLink { KnowHowView() } label: { Label("Know-how cards", systemImage: "book.closed.fill") }
                    NavigationLink { SignalsView() } label: { Label("Alerts, weather radio and satellite SOS", systemImage: "antenna.radiowaves.left.and.right") }
                    NavigationLink { CompassView() } label: { Label("Compass", systemImage: "location.north.circle.fill") }
                }

                Section("Tell people you're okay") {
                    NavigationLink { StatusTextsView() } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Label("Ready-to-send texts", systemImage: "message.fill")
                            Text("\"We're safe, power's out, phones low.\" One tap, filled in for your house.").font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    NavigationLink { GamesView() } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Label("Games for the long evening", systemImage: "dice.fill")
                            Text("Heads up, hangman, trivia, four in a row, shadow puppets and a dozen more. One phone, no signal.").font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                } header: { Text("Pass the time") } footer: {
                    Text("Nothing here replaces 911 or Emergency SOS. If someone is hurt or in danger, call first.")
                }
            }
            .navigationTitle("Toolkit")
        }
    }
}
