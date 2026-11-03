import SwiftUI

struct CompassView: View {
    @StateObject private var provider = HeadingProvider()

    var body: some View {
        VStack(spacing: 28) {
            if let h = provider.heading {
                Text("\(Int(h.rounded()))° \(cardinal(h))")
                    .font(.system(size: 44, weight: .bold, design: .rounded)).monospacedDigit()
                Dial(heading: h).frame(width: 280, height: 280)
                if let a = provider.accuracy, a > 25 {
                    Text("Calibrating: move the phone in a figure eight, away from metal.").font(.footnote).foregroundStyle(.secondary)
                }
            } else if provider.denied {
                ContentUnavailableView("Heading needs permission", systemImage: "location.slash",
                                       description: Text("iOS groups the compass with location. Allow it in Settings. Nothing is stored or sent."))
            } else if !HeadingProvider.isAvailable {
                ContentUnavailableView("No compass on this device", systemImage: "location.north", description: Text("The simulator has no heading sensor."))
            } else {
                ProgressView("Finding north…")
            }
            Text("A bearing, not a map. North is at the top of the dial. Hold the phone flat.")
                .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal)
        }
        .padding()
        .navigationTitle("Compass")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { provider.start() }
        .onDisappear { provider.stop() }
    }

    private func cardinal(_ d: Double) -> String {
        let names = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        return names[Int((d + 11.25).truncatingRemainder(dividingBy: 360) / 22.5)]
    }

    private struct Dial: View {
        let heading: Double
        var body: some View {
            ZStack {
                Circle().stroke(Color.secondary.opacity(0.3), lineWidth: 2)
                ForEach(0..<36, id: \.self) { i in
                    Rectangle()
                        .fill(i % 9 == 0 ? Color.primary : Color.secondary.opacity(0.5))
                        .frame(width: i % 9 == 0 ? 3 : 1.5, height: i % 9 == 0 ? 18 : 10)
                        .offset(y: -128)
                        .rotationEffect(.degrees(Double(i) * 10))
                }
                ForEach(Array(["N", "E", "S", "W"].enumerated()), id: \.offset) { i, label in
                    Text(label).font(.headline).foregroundStyle(label == "N" ? Color.ember : Color.primary)
                        .offset(y: -100)
                        .rotationEffect(.degrees(Double(i) * 90))
                }
            }
            .rotationEffect(.degrees(-heading))
            .overlay(alignment: .top) {
                Image(systemName: "triangle.fill").font(.caption).foregroundStyle(Color.glow).offset(y: -12)
            }
            .animation(.easeOut(duration: 0.2), value: heading)
        }
    }
}
