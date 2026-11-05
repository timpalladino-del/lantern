import SwiftUI
import SwiftData

/// The dashboard. Who is covered, where you stand, what to do this week. Calm numbers, no scores.
struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query private var items: [SupplyItem]
    @Query private var tasks: [MaintenanceTask]
    @Query private var households: [Household]
    @Query private var plans: [HouseholdPlan]
    @Query private var shopping: [ShoppingItem]

    @State private var showScanner = false
    @State private var showAdd = false
    @State private var showShopping = false
    @State private var showNewPerson = false
    @State private var editingPerson: Person?
    @State private var editingPet: Pet?
    @State private var doneCount = 0
    @State private var addedGapIDs: Set<String> = []
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
        SplitContainer {
            List {
                if let h = households.first {
                    householdStrip(h)
                }
                if let report, let h = households.first {
                    standing(report, h)
                }
                planBanner
                trustedContactNudge
                quickActions
                if let report, !report.gaps.isEmpty {
                    gaps(report)
                }
                if let h = households.first, h.hasPeople {
                    whoCanDoWhat(h)
                }
                useThisWeekSection
                equipmentSection
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
            .sheet(item: $paywall) { PaywallView(reason: $0).tint(Color.ink) }
            .sheet(item: $editingPerson) { p in
                if let h = households.first { PersonEditView(household: h, person: p) }
            }
            .sheet(item: $editingPet) { p in
                if let h = households.first { PetEditView(household: h, pet: p) }
            }
            .sheet(isPresented: $showNewPerson) {
                if let h = households.first { PersonEditView(household: h) }
            }
            .sensoryFeedback(.success, trigger: doneCount)
        } detail: {
            if let h = households.first {
                HouseholdView(household: h).navigationTitle("Household")
            } else {
                DetailPlaceholder(symbol: "house", title: "Home", text: "Add yourself on the left to start.")
            }
        }
    }

    // MARK: Household

    @ViewBuilder
    private func householdStrip(_ h: Household) -> some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(h.sortedPeople, id: \.uuid) { p in
                        Button { editingPerson = p } label: { PersonBubble(person: p) }
                            .buttonStyle(.plain)
                    }
                    ForEach(h.petList.sorted { $0.createdAt < $1.createdAt }, id: \.uuid) { pet in
                        Button { editingPet = pet } label: { PetBubble(pet: pet) }
                            .buttonStyle(.plain)
                    }
                    Button { showNewPerson = true } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.title3.weight(.semibold))
                                .frame(width: 56, height: 56)
                                .background(Color(uiColor: .secondarySystemGroupedBackground), in: Circle())
                                .overlay(Circle().strokeBorder(Color.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4])))
                            Text(h.hasPeople ? "Add" : "Add yourself").font(.caption).lineLimit(1)
                        }
                        .frame(width: 64)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add a person")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            NavigationLink { HouseholdView(household: h).navigationTitle("Household") } label: {
                HStack {
                    Image(systemName: "house.fill").foregroundStyle(Color.glow)
                    Text(householdLine(h))
                    Spacer()
                }
            }
        } footer: {
            if h.hasPeople, h.people.contains(where: \.profileIsBare) {
                Text("Tap a person to add age, health, skills and who to call. A dot marks a profile with only a name.")
            } else if !h.hasPeople {
                Text("Start with yourself. Everyone you add sets the food and water target.")
            }
        }
    }

    private func householdLine(_ h: Household) -> String {
        var parts: [String] = []
        let n = h.peopleCount
        parts.append(n == 1 ? "1 person" : "\(n) people")
        if h.petCount > 0 { parts.append(h.petCount == 1 ? "1 pet" : "\(h.petCount) pets") }
        parts.append("covering \(h.targetDays) days")
        return parts.joined(separator: " · ")
    }

    // MARK: Where you stand

    @ViewBuilder
    private func standing(_ r: ReadinessReport, _ h: Household) -> some View {
        Section {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    StatTile(title: "Food", value: ReadinessCalculator.formatDays(r.foodDays), target: r.targetDays, fraction: r.foodFraction)
                    StatTile(title: "Water", value: ReadinessCalculator.formatDays(r.waterDays), target: r.targetDays, fraction: r.waterFraction)
                }
                HStack(spacing: 12) {
                    if let d = r.medicineDays {
                        StatTile(title: "Medication", value: ReadinessCalculator.formatDays(d), target: r.targetDays, fraction: r.medicineFraction)
                    } else {
                        StatTile(title: "Medication", value: r.medications.isEmpty ? "None tracked" : "No count yet", subtitle: "Add under each person", fraction: nil)
                    }
                    if r.petFoodKcalPerDay > 0 {
                        StatTile(title: "Pet food", value: ReadinessCalculator.formatDays(r.petFoodDays), target: r.targetDays, fraction: r.petFoodFraction)
                    } else {
                        StatTile(title: "Equipment", value: r.tasksDue == 0 ? "All checked" : "\(r.tasksDue) due", subtitle: tasks.isEmpty ? "Nothing tracked yet" : "Checks this week", fraction: nil)
                    }
                }
                HStack(spacing: 8) {
                    CountChip(symbol: "clock.badge.exclamationmark", text: r.itemsNeedingAttention == 0 ? "Nothing to use up" : "\(r.itemsNeedingAttention) to use or check")
                    CountChip(symbol: "cart", text: shopping.isEmpty ? "List is empty" : "\(shopping.count) on the list")
                    if r.gaps.isEmpty {
                        CountChip(symbol: "checkmark.circle.fill", text: "No gaps", tint: Color.moss)
                    } else {
                        CountChip(symbol: "arrow.down.right.circle", text: r.gaps.count == 1 ? "1 gap" : "\(r.gaps.count) gaps", tint: Color.ember)
                    }
                }
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
        } header: { Text("Where you stand") } footer: {
            if r.foodIsAssumed {
                Text("Some food has no calorie figure, so 250 per serving is assumed. Scan or type the label for a better number.")
            }
        }
    }

    // MARK: Nudges

    @ViewBuilder
    private var planBanner: some View {
        if let h = households.first, !plan.covers(peopleCount: h.people.count) {
            Section {
                Button { paywall = .secondPerson(coveredDays: report.map { min($0.foodDays, $0.waterDays) }) } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.2.fill").foregroundStyle(Color.glow)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Your plan covers \(plan.plan.maxPeople) of \(h.people.count) people").font(.subheadline.weight(.semibold))
                            Text(plan.plan.isPaid ? "Family has room for everyone in the house." : plan.trialEligible ? "Start a 7-day free trial." : "See plans.").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                    }
                }
                .foregroundStyle(.primary)
            }
        }
    }

    @ViewBuilder
    private var trustedContactNudge: some View {
        if let h = households.first, h.people.count == 1, let plan = plans.first, !plan.hasTrustedContact {
            Section {
                NavigationLink { HouseholdView(household: h).navigationTitle("Household") } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.checkmark").foregroundStyle(Color.glow)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Who checks on you?").font(.subheadline.weight(.semibold))
                            Text("Name someone outside the house. They get your medication card and the plan.").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var quickActions: some View {
        Section {
            HStack(spacing: 12) {
                QuickAction(title: "Scan", symbol: "barcode.viewfinder") { showScanner = true }
                QuickAction(title: "Add", symbol: "plus") { showAdd = true }
                QuickAction(title: "Shopping", symbol: "cart") { showShopping = true }
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
        }
    }

    // MARK: Gaps

    @ViewBuilder
    private func gaps(_ r: ReadinessReport) -> some View {
        Section {
            ForEach(r.gaps.prefix(3)) { gap in
                VStack(alignment: .leading, spacing: 6) {
                    Text(gap.title).font(.subheadline.weight(.medium))
                    Text(gap.detail).font(.caption).foregroundStyle(.secondary)
                    Button(addedGapIDs.contains(gap.id) ? "On the shopping list" : "Add to shopping list") {
                        context.insert(ShoppingItem(name: gap.shoppingName, quantity: gap.shoppingQuantity, unit: gap.shoppingUnit, reason: "Readiness gap"))
                        try? context.save()
                        addedGapIDs.insert(gap.id)
                    }
                    .buttonStyle(.bordered).controlSize(.small)
                    .disabled(addedGapIDs.contains(gap.id))
                }
            }
            if r.gaps.count > 3 {
                Text("and \(r.gaps.count - 3) more under Ready").foregroundStyle(.secondary).font(.subheadline)
            }
        } header: { Text("Close the gaps") }
    }

    // MARK: Who can do what

    @ViewBuilder
    private func whoCanDoWhat(_ h: Household) -> some View {
        let people = h.sortedPeople
        let covered = SkillLibrary.all.filter { skill in people.contains { $0.skillKeys.contains(skill.key) } }
        let missingCore = SkillLibrary.coreKeys.compactMap { SkillLibrary.skill($0) }.filter { s in !people.contains { $0.skillKeys.contains(s.key) } }
        let onPower = people.filter(\.dependsOnPower)
        let needHelp = people.filter { $0.mobility.needsHelpToLeave }
        if !covered.isEmpty || !onPower.isEmpty || !needHelp.isEmpty || people.contains(where: { !$0.emergencyRole.isEmpty }) {
            Section {
                ForEach(onPower, id: \.uuid) { p in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "bolt.fill").foregroundStyle(Color.ember).frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(p.name): \(p.powerDevices.map(\.title).joined(separator: ", "))").font(.subheadline)
                            Text(p.powerDevices.first?.hint ?? "").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                ForEach(needHelp, id: \.uuid) { p in
                    Label("\(p.name) needs help to leave: \(p.mobility.title.lowercased())", systemImage: "figure.roll")
                        .font(.subheadline)
                }
                ForEach(people.filter { !$0.emergencyRole.isEmpty }, id: \.uuid) { p in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checklist").foregroundStyle(.secondary).frame(width: 22)
                        Text("\(p.name): \(p.emergencyRole)").font(.subheadline)
                    }
                }
                if !covered.isEmpty {
                    SkillsWrap(entries: covered.map { s in (s, people.filter { $0.skillKeys.contains(s.key) }.map(\.name)) })
                }
                if !missingCore.isEmpty, covered.count >= 1 {
                    Text("Nobody is marked for \(missingCore.map { $0.title.lowercased() }.joined(separator: ", ")). Mark whoever can, or pick one to learn.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            } header: { Text("Who can do what") }
        } else {
            Section {
                Button { if let first = people.first { editingPerson = first } } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.text.rectangle").foregroundStyle(Color.glow)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Who can do what?").font(.subheadline.weight(.semibold))
                            Text("Mark first aid, the generator, the gas shutoff, and anything that runs on power.").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                    }
                }
                .foregroundStyle(.primary)
            }
        }
    }

    // MARK: This week

    private var useThisWeekSection: some View {
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
    }

    private var equipmentSection: some View {
        Section("Equipment this week") {
            if dueTasks.isEmpty {
                Text(tasks.isEmpty ? "Add your generator, alarms or extinguisher under Equipment." : "No checks due this week.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(dueTasks.prefix(6), id: \.uuid) { task in
                    TaskRow(task: task) { markDone(task) }
                }
            }
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

// MARK: - Pieces

struct PersonBubble: View {
    let person: Person

    private var badge: String? {
        if person.dependsOnPower { return "bolt.fill" }
        if person.medications.contains(where: \.isCritical) { return "exclamationmark" }
        if !person.medications.isEmpty { return "pills.fill" }
        return nil
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .bottomTrailing) {
                Text(person.initials)
                    .font(.headline)
                    .frame(width: 56, height: 56)
                    .background(Color.glow.opacity(0.22), in: Circle())
                    .overlay(Circle().strokeBorder(Color.glow.opacity(0.6), lineWidth: 1.5))
                if let badge {
                    Image(systemName: badge)
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 18, height: 18)
                        .background(Color(uiColor: .systemGroupedBackground), in: Circle())
                        .overlay(Circle().strokeBorder(Color.glow.opacity(0.6), lineWidth: 1))
                        .offset(x: 2, y: 2)
                } else if person.profileIsBare {
                    Circle().fill(Color.ember).frame(width: 10, height: 10).offset(x: 1, y: 1)
                }
            }
            Text(person.name).font(.caption).lineLimit(1)
            Text(subtitle).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
        }
        .frame(width: 64)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(person.name), \(subtitle)")
    }

    private var subtitle: String {
        if person.isInfant { return "Baby" }
        if let a = person.age { return "\(a)" }
        return person.profileIsBare ? "Add details" : " "
    }
}

struct PetBubble: View {
    let pet: Pet
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: pet.species == .cat ? "cat.fill" : pet.species == .dog ? "dog.fill" : "pawprint.fill")
                .font(.title3)
                .frame(width: 56, height: 56)
                .background(Color.moss.opacity(0.22), in: Circle())
                .overlay(Circle().strokeBorder(Color.moss.opacity(0.6), lineWidth: 1.5))
            Text(pet.name).font(.caption).lineLimit(1)
            Text(pet.species.title).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
        }
        .frame(width: 64)
    }
}

/// "First aid: Maria, Tim" as a flowing list. Plain text rows keep it readable at any size.
struct SkillsWrap: View {
    let entries: [(Skill, [String])]
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(entries, id: \.0.key) { skill, names in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: skill.symbol).foregroundStyle(.secondary).frame(width: 22)
                    Text(skill.title).font(.subheadline)
                    Spacer()
                    Text(names.joined(separator: ", ")).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.trailing)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

struct CountChip: View {
    let symbol: String
    let text: String
    var tint: Color = .secondary
    var body: some View {
        Label(text, systemImage: symbol)
            .font(.caption2.weight(.medium))
            .lineLimit(2)
            .minimumScaleFactor(0.85)
            .multilineTextAlignment(.leading)
            .foregroundStyle(tint == .secondary ? Color.primary : tint)
            .padding(.horizontal, 8).padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct StatTile: View {
    let title: String
    let value: String
    var target: Int = 0
    var subtitle: String? = nil
    let fraction: Double?

    init(title: String, value: String, target: Int, fraction: Double) {
        self.title = title; self.value = value; self.target = target; self.fraction = fraction; self.subtitle = nil
    }
    init(title: String, value: String, subtitle: String, fraction: Double?) {
        self.title = title; self.value = value; self.subtitle = subtitle; self.fraction = fraction
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3.weight(.semibold)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.7)
            if let fraction {
                ProgressView(value: fraction).tint(Color.glow)
            } else {
                ProgressView(value: 0).tint(Color.glow).opacity(0.3)
            }
            Text(subtitle ?? "Goal: \(target) days").font(.caption2).foregroundStyle(.secondary).lineLimit(1)
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
