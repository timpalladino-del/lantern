import SwiftUI
import SwiftData

struct OutageView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \OutageEvent.startedAt, order: .reverse) private var outages: [OutageEvent]
    @Query private var items: [SupplyItem]
    @Query private var plans: [HouseholdPlan]
    @Query private var tasks: [MaintenanceTask]
    @Query private var households: [Household]
    @AppStorage(AppSettings.checkInEnabled) private var checkInEnabled = false
    @AppStorage(AppSettings.checkInHours) private var checkInHours = 4

    private var active: OutageEvent? { outages.first { $0.isActive } }
    /// Medications marked "Keep refrigerated" under any person. Shown beside the fridge clock.
    private var refrigeratedMedications: [Medication] {
        (households.first?.sortedPeople ?? []).flatMap(\.medications).filter { $0.instructions.contains(.refrigerate) }
    }
    private let library = KnowHowLibrary.shared

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            List {
                statusSection(now: timeline.date)
                if let o = active { clocksSection(o, now: timeline.date) }
                whatYouHaveSection
                batterySection
                generatorSection
                if active != nil { checkInSection }
                if outages.contains(where: { !$0.isActive }) { historySection }
            }
        }
        .navigationTitle("Outage mode")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func statusSection(now: Date) -> some View {
        Section {
            if let o = active {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Power out for \(durationText(from: o.startedAt, to: now))").font(.headline)
                    Text("Started \(o.startedAt.formatted(date: .abbreviated, time: .shortened)).").font(.subheadline).foregroundStyle(.secondary)
                    Button("Power is back") {
                        o.endedAt = Date()
                        try? context.save()
                        if checkInEnabled { NotificationScheduler.shared.cancelCheckIn() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.vertical, 4)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Lights just went out?").font(.headline)
                    Text("Start the clock now. The fridge and freezer timers count from this moment, and this screen becomes your checklist.").font(.subheadline).foregroundStyle(.secondary)
                    Button {
                        context.insert(OutageEvent())
                        try? context.save()
                    } label: { Label("Power just went out", systemImage: "powerplug.fill") }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.vertical, 4)
            }
        }
    }

    @ViewBuilder
    private func clocksSection(_ o: OutageEvent, now: Date) -> some View {
        Section {
            ClockRow(title: "Refrigerator", symbol: "refrigerator.fill", deadline: o.fridgeDeadline, now: now,
                     safeText: "Keep the door shut. Perishables are fine until",
                     pastText: "Past 4 hours. Toss meat, dairy, eggs, leftovers and cut produce.")
            ClockRow(title: o.freezerIsFull ? "Freezer (full)" : "Freezer (half full)", symbol: "snowflake", deadline: o.freezerDeadline, now: now,
                     safeText: "Door shut, it holds until",
                     pastText: "Check it. Food with ice crystals or at 40°F or below can be refrozen.")
            Toggle("Freezer is full", isOn: Binding(get: { o.freezerIsFull }, set: { o.freezerIsFull = $0; try? context.save() }))
            Stepper("Fridge opened \(o.fridgeOpenedCount) time\(o.fridgeOpenedCount == 1 ? "" : "s")", value: Binding(get: { o.fridgeOpenedCount }, set: { o.fridgeOpenedCount = $0; try? context.save() }), in: 0...50)
            if o.fridgeOpenedCount >= 3 {
                Text("Every opening lets the cold out. Treat the fridge window as shorter than 4 hours.").font(.footnote).foregroundStyle(Color.ember)
            }
            let cold = refrigeratedMedications
            if !cold.isEmpty {
                NavigationLink {
                    if let card = library.card("refrigerated_meds") { KnowHowCardView(card: card) }
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("In the fridge: \(cold.map { m in m.person.map { "\(m.name) (\($0.name))" } ?? m.name }.joined(separator: ", "))")
                            Text("Most keep for days at room temperature in a cooler, away from ice. Check the label or call the pharmacy.").font(.footnote).foregroundStyle(.secondary)
                        }
                    } icon: { Image(systemName: "pills.fill").foregroundStyle(Color.ink) }
                }
            }
        } header: { Text("Food clocks") } footer: {
            Text("USDA: fridge about 4 hours unopened; full freezer about 48 hours, half-full about 24. Never taste to check.")
        }
    }

    private var whatYouHaveSection: some View {
        Section("What you have right now") {
            let lightKeywords = ["flashlight", "headlamp", "lantern", "candle", "glow", "light"]
            let lights = items.filter { item in
                item.quantity > 0 && item.category == .power && lightKeywords.contains { item.name.lowercased().contains($0) }
            }
            let batteries = items.filter { $0.quantity > 0 && $0.category == .power && (($0.shelfLifeKey ?? "").hasPrefix("batteries") || $0.name.lowercased().contains("batter")) }
            let water = items.filter { $0.quantity > 0 && $0.category == .water }
            LabeledContent("Lights", value: lights.isEmpty ? "None logged" : lights.map { "\(Int($0.quantity)) \($0.name)" }.joined(separator: ", "))
            LabeledContent("Batteries", value: batteries.isEmpty ? "None logged" : batteries.map { "\(Int($0.quantity)) \($0.name)" }.joined(separator: ", "))
            LabeledContent("Water", value: water.isEmpty ? "None logged" : String(format: "%.1f gallons", water.reduce(0.0) { $0 + $1.totalLiters } / 3.785))
            if let h = households.first {
                let r = ReadinessCalculator.compute(items: items, tasks: tasks, household: h)
                LabeledContent("Food", value: ReadinessCalculator.formatDays(r.foodDays))
                if let d = r.medicineDays { LabeledContent("Medication", value: ReadinessCalculator.formatDays(d)) }
            }
            let cash = items.filter { $0.category == .cash && $0.quantity > 0 }
            if !cash.isEmpty { LabeledContent("Cash", value: cash.map { "\(Int($0.quantity)) \($0.unit)" }.joined(separator: ", ")) }
        }
    }

    private var batterySection: some View {
        Section("This phone") {
            let r = BatteryMonitor.read()
            if let level = r.level {
                LabeledContent("Battery", value: "\(Int(level * 100))%\(r.isCharging ? ", charging" : "")")
                ProgressView(value: level).tint(level < 0.2 ? Color.ember : Color.glow)
            }
            ForEach(BatteryMonitor.tips(for: r), id: \.self) { tip in
                Label(tip, systemImage: "bolt.horizontal.fill").font(.subheadline)
            }
        }
    }

    private var generatorSection: some View {
        Section {
            if let card = library.card("generator") {
                NavigationLink { KnowHowCardView(card: card) } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Generator: outside only, 20 feet from the house", systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline.weight(.semibold))
                        Text("Never in a garage, basement or porch. Carbon monoxide has no smell. Tap for the full card.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            if let co = library.card("co_alarm") {
                NavigationLink { KnowHowCardView(card: co) } label: { Label("If the CO alarm sounds", systemImage: "wind") }
            }
            if let f = library.card("fridge_freezer") {
                NavigationLink { KnowHowCardView(card: f) } label: { Label("Is the food still safe?", systemImage: "refrigerator.fill") }
            }
        } header: { Text("Safety") }
    }

    private var checkInSection: some View {
        Section {
            Toggle("Remind me to check in with my people", isOn: $checkInEnabled)
                .onChange(of: checkInEnabled) { _, on in
                    Task {
                        if on {
                            let ok = await NotificationScheduler.shared.requestAuthorization()
                            if ok { await NotificationScheduler.shared.scheduleCheckIn(everyHours: checkInHours, contactNames: plans.first?.trustedContacts.map(\.name) ?? []) } else { checkInEnabled = false }
                        } else {
                            NotificationScheduler.shared.cancelCheckIn()
                        }
                    }
                }
            if checkInEnabled {
                Picker("Every", selection: $checkInHours) {
                    ForEach([2, 4, 6, 12], id: \.self) { Text("\($0) hours").tag($0) }
                }
                .onChange(of: checkInHours) { _, h in Task { await NotificationScheduler.shared.scheduleCheckIn(everyHours: h, contactNames: plans.first?.trustedContacts.map(\.name) ?? []) } }
            }
        } header: { Text("Check in") } footer: {
            Text("A nudge to text where you are, that you're okay, and how much battery you have. Texts get through when calls don't.")
        }
    }

    private var historySection: some View {
        Section("Past outages") {
            ForEach(outages.filter { !$0.isActive }, id: \.uuid) { o in
                HStack {
                    Text(o.startedAt.formatted(date: .abbreviated, time: .shortened))
                    Spacer()
                    Text(durationText(from: o.startedAt, to: o.endedAt ?? o.startedAt)).foregroundStyle(.secondary)
                }
                .swipeActions { Button(role: .destructive) { context.delete(o); try? context.save() } label: { Label("Delete", systemImage: "trash") } }
            }
        }
    }

    private func durationText(from a: Date, to b: Date) -> String {
        let mins = max(0, Int(b.timeIntervalSince(a) / 60))
        if mins < 60 { return "\(mins) min" }
        let h = mins / 60, m = mins % 60
        if h < 24 { return m == 0 ? "\(h) h" : "\(h) h \(m) min" }
        return "\(h / 24) d \(h % 24) h"
    }
}

struct ClockRow: View {
    let title: String
    let symbol: String
    let deadline: Date
    let now: Date
    let safeText: String
    let pastText: String

    var body: some View {
        let remaining = deadline.timeIntervalSince(now)
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol).frame(width: 28).foregroundStyle(remaining > 0 ? Color.moss : Color.ember)
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(title).font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(remaining > 0 ? remainingText(remaining) : "Time's up")
                        .font(.subheadline.weight(.semibold)).monospacedDigit()
                        .foregroundStyle(remaining > 0 ? Color.moss : Color.ember)
                }
                Text(remaining > 0 ? "\(safeText) \(deadline.formatted(date: .omitted, time: .shortened))." : pastText)
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func remainingText(_ s: TimeInterval) -> String {
        let mins = Int(s / 60)
        if mins < 60 { return "\(mins) min left" }
        return "\(mins / 60) h \(mins % 60) min left"
    }
}
