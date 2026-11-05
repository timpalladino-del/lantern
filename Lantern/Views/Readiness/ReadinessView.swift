import SwiftUI
import SwiftData

struct ReadinessView: View {
    @Environment(\.modelContext) private var context
    @Query private var items: [SupplyItem]
    @Query private var tasks: [MaintenanceTask]
    @Query private var households: [Household]

    var body: some View {
        SplitContainer {
            Group {
                if let household = households.first {
                    content(household: household)
                } else {
                    ProgressView().task { SeedData.ensureDefaults(in: context) }
                }
            }
            .navigationTitle("Ready")
        } detail: {
            DetailPlaceholder(symbol: "checkmark.shield", title: "Readiness in days", text: "Tap the household on the left to work on who is covered.")
        }
    }

    @ViewBuilder
    private func content(household: Household) -> some View {
        let report = ReadinessCalculator.compute(items: items, tasks: tasks, household: household)
        List {
            Section {
                NavigationLink {
                    HouseholdView(household: household)
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(household.hasPeople ? household.sortedPeople.map(\.name).joined(separator: ", ") : "Add the people you're covering")
                        Text(householdSubtitle(household, report)).font(.caption).foregroundStyle(.secondary)
                    }
                }
            } header: { Text("Who is covered") }

            Section("Where you stand") {
                ReadinessBar(title: "Food", value: ReadinessCalculator.formatDays(report.foodDays), fraction: report.foodFraction,
                             detail: "\(Int(report.caloriesOnHand.rounded())) calories on hand, \(Int(report.caloriesPerDay.rounded())) needed a day."
                                + (report.foodIsAssumed ? " Some items have no calorie figure, so 250 per serving is assumed." : ""))
                ReadinessBar(title: "Water", value: ReadinessCalculator.formatDays(report.waterDays), fraction: report.waterFraction,
                             detail: String(format: "%.1f gallons on hand, %.1f needed a day. One gallon per person, plus pets.", report.waterLiters / 3.785, report.waterLitersPerDay / 3.785))
                if report.petFoodKcalPerDay > 0 {
                    ReadinessBar(title: "Pet food", value: ReadinessCalculator.formatDays(report.petFoodDays), fraction: report.petFoodFraction,
                                 detail: "\(Int(report.petFoodCalories.rounded())) calories of pet food on hand, \(Int(report.petFoodKcalPerDay.rounded())) needed a day."
                                    + (report.petFoodIsEstimated ? " Pet needs estimated from weight; set cups or cans a day on each pet for a better number." : "")
                                    + (report.petFoodIsAssumed ? " Some pet food has no calorie figure, so typical values are assumed." : ""))
                }
                if let d = report.medicineDays {
                    ReadinessBar(title: "Medication", value: ReadinessCalculator.formatDays(d), fraction: report.medicineFraction,
                                 detail: "Shortest supply across \(report.medications.count) tracked medication\(report.medications.count == 1 ? "" : "s").")
                } else {
                    LabeledContent("Medication", value: "None tracked")
                }
                if report.itemsNeedingAttention > 0 {
                    LabeledContent("Items to use or check", value: "\(report.itemsNeedingAttention)")
                }
                if report.tasksDue > 0 {
                    LabeledContent("Equipment checks due", value: "\(report.tasksDue)")
                }
            }

            if !report.medications.isEmpty {
                Section("Medications") {
                    ForEach(report.medications) { m in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(m.name)
                                    if m.isCritical { Image(systemName: "exclamationmark.circle.fill").foregroundStyle(Color.ember).font(.caption) }
                                }
                                Text(m.personName).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(m.daysOfSupply.map { ReadinessCalculator.formatDays($0) } ?? "–")
                                .font(.subheadline)
                                .foregroundStyle((m.daysOfSupply ?? 99) < Double(report.targetDays) ? Color.ember : Color.secondary)
                        }
                    }
                }
            }

            Section {
                if report.gaps.isEmpty {
                    Label("You are covered for \(report.targetDays) days of food, water and medication.", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(Color.moss)
                        .symbolEffect(.bounce, value: report.gaps.count)
                }
                ForEach(report.gaps) { gap in GapRow(gap: gap) }
            } header: { Text("Gaps") } footer: {
                Text("Calories per person follow Mifflin-St Jeor when weight and height are known, otherwise USDA Dietary Guidelines. Water follows CDC and Ready.gov. Planning numbers, not medical advice.")
            }
        }
    }

    private func householdSubtitle(_ h: Household, _ r: ReadinessReport) -> String {
        var parts: [String] = []
        parts.append(r.people == 1 ? "1 person" : "\(r.people) people")
        if r.pets > 0 { parts.append(r.pets == 1 ? "1 pet" : "\(r.pets) pets") }
        parts.append("\(r.targetDays)-day goal")
        return parts.joined(separator: " · ")
    }
}

private struct ReadinessBar: View {
    let title: String
    let value: String
    let fraction: Double
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.subheadline.weight(.medium))
                Spacer()
                Text(value).font(.subheadline)
            }
            ProgressView(value: fraction).tint(Color.glow)
            Text(detail).font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
