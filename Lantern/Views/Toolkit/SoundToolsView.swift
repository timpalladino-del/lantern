import SwiftUI

struct SoundToolsView: View {
    @State private var tone = ToneGenerator.shared
    @State private var sleepMinutes = 30

    private var alarmOn: Bool { tone.current == .alarm }

    var body: some View {
        List {
            Section {
                Button {
                    if alarmOn { tone.stop() } else { tone.start(.alarm) }
                } label: {
                    Label(alarmOn ? "Stop the alarm" : "Sound the alarm", systemImage: alarmOn ? "stop.circle.fill" : "speaker.wave.3.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.borderedProminent)
                .tint(alarmOn ? Color.ember : Color.ink)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } header: { Text("Attention") } footer: {
                Text("A loud two-tone whistle for being found under debris, across a flooded yard, or in a dark house. Turn the volume all the way up first. It plays through the speaker, not headphones.")
            }

            Section {
                ForEach([ToneGenerator.Sound.rain, .pinkNoise, .brownNoise]) { s in
                    Button {
                        if tone.current == s { tone.stop() } else { tone.start(s, minutes: sleepMinutes == 0 ? nil : sleepMinutes) }
                    } label: {
                        HStack {
                            Label(s.title, systemImage: symbol(for: s))
                            Spacer()
                            if tone.current == s { Image(systemName: "waveform").foregroundStyle(Color.glow).symbolEffect(.variableColor.iterative, isActive: true) }
                        }
                    }
                    .foregroundStyle(.primary)
                }
                Picker("Stop after", selection: $sleepMinutes) {
                    Text("15 min").tag(15); Text("30 min").tag(30); Text("1 hour").tag(60); Text("Keep playing").tag(0)
                }
            } header: { Text("Sleep sounds") } footer: {
                Text("For kids sleeping through a storm, or you. Generated on the phone, so there is nothing to download. Keep the phone plugged in or use the timer.")
            }
        }
        .navigationTitle("Sound")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func symbol(for s: ToneGenerator.Sound) -> String {
        switch s {
        case .alarm: return "speaker.wave.3.fill"
        case .rain: return "cloud.rain.fill"
        case .pinkNoise: return "waveform"
        case .brownNoise: return "waveform.path"
        }
    }
}
