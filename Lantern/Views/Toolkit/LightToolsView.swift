import SwiftUI
import UIKit

struct LightToolsView: View {
    @State private var torch = TorchController.shared
    @State private var screenMode: LightScreenView.Mode?
    @AppStorage(AppSettings.strobeWarningSeen) private var strobeWarningSeen = false
    @State private var pendingFlash: PendingFlash?

    /// What to start once the one-time flashing-light notice is acknowledged.
    private enum PendingFlash: Identifiable {
        case torch(TorchController.Pattern), screen(LightScreenView.Mode)
        var id: String { switch self { case .torch(let p): return "torch-\(p.rawValue)"; case .screen(let m): return "screen-\(m.rawValue)" } }
    }

    private func startTorch(_ p: TorchController.Pattern) {
        if (p == .sos || p == .slowBlink), !strobeWarningSeen { pendingFlash = .torch(p) } else { torch.set(p) }
    }

    private func startScreen(_ m: LightScreenView.Mode) {
        if m == .flasher, !strobeWarningSeen { pendingFlash = .screen(m) } else { screenMode = m }
    }

    private func confirmPending() {
        strobeWarningSeen = true
        switch pendingFlash {
        case .torch(let p): torch.set(p)
        case .screen(let m): screenMode = m
        case nil: break
        }
        pendingFlash = nil
    }

    var body: some View {
        List {
            Section {
                if torch.isAvailable {
                    Picker("Camera light", selection: Binding(get: { torch.pattern }, set: { startTorch($0) })) {
                        ForEach(TorchController.Pattern.allCases) { p in Text(p.title).tag(p) }
                    }
                    .pickerStyle(.segmented)
                    if torch.pattern != .off {
                        Button(role: .destructive) { torch.stop() } label: { Label("Turn off", systemImage: "stop.circle.fill") }
                        // Re-reads the clock every minute, so the warning appears even if nothing else redraws.
                        TimelineView(.periodic(from: .now, by: 60)) { _ in
                            if torch.minutesRunning >= 10 {
                                Label("Running \(torch.minutesRunning) minutes. The LED drains the battery; switch to a real flashlight if you have one.", systemImage: "battery.25percent")
                                    .font(.footnote).foregroundStyle(Color.ember)
                            }
                        }
                    }
                } else {
                    Text("No camera light on this device.").foregroundStyle(.secondary)
                }
            } header: { Text("SOS strobe") } footer: {
                Text("SOS is three short, three long, three short, repeated. Slow blink says \"I'm here\" and uses far less battery. Point it at the sky or a window.")
            }

            Section {
                Button { screenMode = .white } label: { Label("White screen light", systemImage: "sun.max.fill") }
                Button { screenMode = .amber } label: { Label("Warm screen light", systemImage: "sun.min.fill") }
                Button { screenMode = .candle } label: { Label("Candle", systemImage: "flame.fill") }
                Button { startScreen(.flasher) } label: { Label("Be seen: flashing screen", systemImage: "rays") }
            } header: { Text("Screen light") } footer: {
                Text("The screen goes to full brightness and stays awake until you close it. Tap the screen to show the close button.")
            }
        }
        .navigationTitle("Light")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $screenMode) { mode in LightScreenView(mode: mode) }
        .alert("Flashing light", isPresented: Binding(get: { pendingFlash != nil }, set: { if !$0 { pendingFlash = nil } })) {
            Button("Start") { confirmPending() }
            Button("Cancel", role: .cancel) { pendingFlash = nil }
        } message: {
            Text("A flashing light can trigger a seizure in someone with photosensitive epilepsy. Point it away from faces and at the sky or a window. This notice shows once.")
        }
    }
}

struct LightScreenView: View {
    enum Mode: String, Identifiable {
        case white, amber, candle, flasher
        var id: String { rawValue }
    }

    let mode: Mode
    @Environment(\.dismiss) private var dismiss
    @State private var showControls = true
    @State private var previousBrightness: CGFloat = 0.5

    var body: some View {
        ZStack {
            content.ignoresSafeArea()
            if showControls {
                VStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Label("Close", systemImage: "xmark.circle.fill")
                            .font(.headline)
                            .padding(.horizontal, 18).padding(.vertical, 10)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { withAnimation { showControls.toggle() } }
        .statusBarHidden(true)
        .onAppear {
            previousBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = mode == .candle ? 0.6 : 1.0
            ScreenAwake.hold()
        }
        .onDisappear {
            UIScreen.main.brightness = previousBrightness
            ScreenAwake.release()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch mode {
        case .white:
            Color.white
        case .amber:
            Color(red: 1.0, green: 0.80, blue: 0.50)
        case .candle:
            TimelineView(.animation) { tl in
                let t = tl.date.timeIntervalSinceReferenceDate
                let flicker = 0.72 + 0.12 * sin(t * 7.3) + 0.08 * sin(t * 13.1) + 0.05 * sin(t * 29.7)
                ZStack {
                    Color.black
                    RadialGradient(colors: [Color(red: 1.0, green: 0.70, blue: 0.32).opacity(flicker), Color(red: 0.9, green: 0.45, blue: 0.1).opacity(flicker * 0.35), .black],
                                   center: .center, startRadius: 20, endRadius: 520)
                }
            }
        case .flasher:
            TimelineView(.periodic(from: .now, by: 0.25)) { tl in
                let on = Int(tl.date.timeIntervalSinceReferenceDate * 4) % 2 == 0
                (on ? Color.white : Color.black)
            }
        }
    }
}
