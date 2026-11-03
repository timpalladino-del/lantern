import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query private var items: [SupplyItem]
    @Query private var tasks: [MaintenanceTask]
    @Query private var households: [Household]

    @State private var showScanner = false
    @State private var showAdd = false
    @State private var showShopping = false
    @State private var doneCount = 0
    @State private var paywall: PaywallReason?
    @State private var plan = PlanStore.shared

    private var now: Date { Date() }

    private var useThisWeek: [SupplyItem] {
        items.filter { $0.status(on: now).needsAttention && $0.quantity > 0 }
            .sorted { ($0.daysUntilExpiration(from: now) ?? 0) < ($1.daysUntilExpiration(from: now) ?? 0) }
    }

    private var dueTasks: [MaintenanceTask] {
        tasks.filter { $0.isEnabled && $0.daysUntilDue(from: now) <= 7 }
            .sorted { $0.nextDue < $1.nextDue }
    }

    private var report: ReadinessReport? {
        guard let household = households.first else { return nil }
        return ReadinessCalculator.compute(items: items, tasks: tasks, household: household, now: now)
    }

    var body: some View {
        NavigationStack {
            List {
                if let report {
                    Section {
                        HStack(spacing: 12) {
                            StatTile(title: "Food", value: ReadinessCalculator.formatDays(report.foodDays), target: report.targetDays, fraction: report.foodFraction)
                            StatTile(title: "Water", value: ReadinessCalculator.formatDays(report.waterDays), target: report.targetDays, fraction: report.waterFraction)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                    }
                }

                if let h = households.first, !plan.covers(peopleCount: h.people.count) {
                    Section {
                        Button { paywall = .secondPerson(coveredDays: report.map { min($0.foodDays, $0.waterDays) }) } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "person.2.fill").foregroundStyle(Color.glow)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Your plan covers 1 of \(h.people.count) people").font(.subheadline.weight(.semibold))
                                    Text(plan.trialEligible ? "Start a 7-day free trial of Family." : "See Family plans.").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }

                Section {
                    HStack(spacing: 12) {
                        QuickAction(title: "Scan", symbol: "barcode.viewfinder") { showScanner = true }
                        QuickAction(title: "Add", symbol: "plus") { showAdd = true }
                        QuickAction(title: "Shopping", symbol: "cart") { showShopping = true }
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                }

                Section("Use this week") {
                    if useThisWeek.isEmpty {
                        Text(items.isEmpty ? "Add a few supplies and this fills in." : "Nothing is close to its date. Nice.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(useThisWeek.prefix(8)) { item in
                            NavigationLink { ItemDetailView(item: item) } label: { ItemRow(item: item) }
                        }
                        if useThisWeek.count > 8 {
                            Text("and \(useThisWeek.count - 8) more in Supplies").foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Equipment this week") {
                    if dueTasks.isEmpty {
                        Text(tasks.isEmpty ? "Add your generator, alarms or extinguisher under Equipment." : "No checks due this week.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(dueTasks.prefix(6), id: \.uuid) { task in
                            TaskRow(task: task) {
                                markDone(task)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink { SettingsView() } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showScanner) { ScanSheet() }
            .sheet(isPresented: $showAdd) { ItemEditView() }
            .sheet(isPresented: $showShopping) { ShoppingListView() }
            .sheet(item: $paywall) { PaywallView(reason: $0).tint(Color.accentColor) }
            .sensoryFeedback(.success, trigger: doneCount)
        }
    }

    private func markDone(_ task: MaintenanceTask) {
        task.lastDoneAt = Date()
        doneCount += 1
        if let equipment = task.equipment {
            let log = MaintenanceLog(taskTitle: task.title)
            log.equipment = equipment
            context.insert(log)
        }
        try? context.save()
    }
}

struct StatTile: View {
    let title: String
    let value: String
    let target: Int
    let fraction: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3.weight(.semibold)).monospacedDigit()
            ProgressView(value: fraction).tint(Color.glow)
            Text("Goal: \(target) days").font(.caption2).foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct QuickAction: View {
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: symbol).font(.title3)
                Text(title).font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

struct TaskRow: View {
    let task: MaintenanceTask
    let onDone: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                HStack(spacing: 4) {
                    if let name = task.equipment?.name { Text(name) }
                    Text("·").foregroundStyle(.tertiary)
                    Text(dueText)
                }
                .font(.caption)
                .foregroundStyle(task.isDue() ? Color.ember : Color.secondary)
            }
            Spacer()
            Button("Done", action: onDone)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
    }

    private var dueText: String {
        let d = task.daysUntilDue()
        if d < 0 { return "\(-d)d overdue" }
        if d == 0 { return "Due today" }
        return "Due in \(d)d"
    }
}
