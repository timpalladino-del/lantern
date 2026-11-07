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
    @State private var paywall: PaywallReason?
    @State private var plan = PlanStore.shared
    @State private var weather = WeatherAlertStore.shared

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
                weatherBanner
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
            .task {
                if weather.hasPlaces, weather.isStale() { await weather.refresh(notify: true) }
            }
        } detail: {
            if let h = households.first {
                HouseholdView(household: h)
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

            NavigationLink { HouseholdView(household: h) } label: {
                HStack {
                    Image(systemName: "house.fill").foregroundStyle(Color.ink)
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
        let n = h.people.count
        parts.append(n == 0 ? "No one added yet" : n == 1 ? "1 person" : "\(n) people")
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
                        StatTile(title: "Gear", value: r.tasksDue == 0 ? "All checked" : "\(r.tasksDue) due", subtitle: tasks.isEmpty ? "Nothing tracked yet" : "Checks this week", fraction: nil)
                    }
                }
                if let line = r.weakestLinkLine {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Image(systemName: r.weakestLink.map { $0.days >= Double(r.targetDays) } == true ? "checkmark.circle.fill" : "arrow.down.right.circle.fill")
                            .foregroundStyle(r.weakestLink.map { $0.days >= Double(r.targetDays) } == true ? Color.moss : Color.ember)
                        Text(line).font(.subheadline)
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
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
        if let h = households.first, !plan.covers(peopleCount: h.people.count), plan.plan < .family10 {
            let next = plan.plan.next(forPeople: h.people.count)
            Section {
                Button {
                    paywall = plan.plan == .free ? .secondPerson(coveredDays: report.map { min($0.foodDays, $0.waterDays) }) : (plan.reasonForAdding(personNumber: h.people.count) ?? .plans)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.2.fill").foregroundStyle(Color.ink)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Your plan covers \(plan.plan.maxPeople) of \(h.people.count) people").font(.subheadline.weight(.semibold))
                            Text(plan.plan.isPaid ? "\(next.title) has room for everyone in the house." : plan.trialEligible ? "Start a 7-day free trial." : "See plans.").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                    }
                }
                .foregroundStyle(.primary)
            }
        }
    }

    /// The worst alert in effect for a saved place. Nothing shows when the sky is quiet or no place is saved.
    @ViewBuilder
    private var weatherBanner: some View {
        let active = weather.activeAlerts(now: now)
        if let top = active.first {
            Section {
                NavigationLink { WeatherAlertsView() } label: {
                    HStack(spacing: 12) {
                        Image(systemName: top.isWarning ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill")
                            .foregroundStyle(top.isWarning ? Color.ember : Color.ink)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(active.count > 1 ? "\(top.event) and \(active.count - 1) more" : top.event).font(.subheadline.weight(.semibold))
                            Text([top.placeNames.joined(separator: ", "), top.untilText(now: now)].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var trustedContactNudge: some View {
        if let h = households.first, h.people.count == 1, let plan = plans.first, !plan.hasTrustedContact {
            Section {
                NavigationLink { HouseholdView(household: h) } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.checkmark").foregroundStyle(Color.ink)
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
            ForEach(r.gaps.prefix(3)) { gap in GapRow(gap: gap) }
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
                    Button { editingPerson = p } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "bolt.fill").foregroundStyle(Color.ember).frame(width: 22)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(p.name): \(p.powerDevices.map(\.title).joined(separator: ", "))").font(.subheadline)
                                Text(p.powerDevices.first?.hint ?? "").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                        }
                    }
                    .foregroundStyle(.primary)
                }
                ForEach(needHelp, id: \.uuid) { p in
                    Button { editingPerson = p } label: {
                        HStack {
                            Label("\(p.name) needs help to leave: \(p.mobility.title.lowercased())", systemImage: "figure.roll").font(.subheadline)
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                        }
                    }
                    .foregroundStyle(.primary)
                }
                ForEach(people.filter { !$0.emergencyRole.isEmpty }, id: \.uuid) { p in
                    Button { editingPerson = p } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checklist").foregroundStyle(.secondary).frame(width: 22)
                            Text("\(p.name): \(p.emergencyRole)").font(.subheadline)
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                        }
                    }
                    .foregroundStyle(.primary)
                }
                if !covered.isEmpty {
                    SkillsWrap(entries: covered.map { s in (s, people.filter { $0.skillKeys.contains(s.key) }) }) { editingPerson = $0 }
                }
                if !missingCore.isEmpty, covered.count >= 1 {
                    Text("Nobody is marked for \(missingCore.map { $0.title.lowercased() }.joined(separator: ", ")). Tap a name to mark who can, or pick one to learn.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                NavigationLink { HouseholdView(household: h) } label: {
                    Label("Everyone's skills and needs", systemImage: "person.2.fill").font(.subheadline)
                }
            } header: { Text("Who can do what") } footer: {
                Text("Tap a name to change what they can do.")
            }
        } else {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "person.text.rectangle").foregroundStyle(Color.ink)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Who can do what?").font(.subheadline.weight(.semibold))
                        Text("Mark first aid, the generator, the gas shutoff, and anything that runs on power.").font(.caption).foregroundStyle(.secondary)
                    }
                }
                ForEach(people, id: \.uuid) { p in
                    Button { editingPerson = p } label: {
                        HStack {
                            Text(p.name)
                            Spacer()
                            Text("Mark skills").font(.caption).foregroundStyle(.secondary)
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                        }
                    }
                    .foregroundStyle(.primary)
                }
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
        Section("Gear this week") {
            if dueTasks.isEmpty {
                Text(tasks.isEmpty ? "Add your generator, alarms or extinguisher under Gear." : "No checks due this week.")
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
                Avatar(photoData: person.photoData, fallback: .initials(person.initials))
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
            Avatar(photoData: pet.photoData, fallback: .symbol(pet.avatarSymbol), tint: Color.moss)
            Text(pet.name).font(.caption).lineLimit(1)
            Text(pet.species.title).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
        }
        .frame(width: 64)
    }
}

/// "First aid: Maria, Tim" as a flowing list. Plain text rows keep it readable at any size.
/// One row per skill with the names of the people who have it. Each name opens that person.
struct SkillsWrap: View {
    let entries: [(Skill, [Person])]
    var onPick: (Person) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(entries, id: \.0.key) { skill, people in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: skill.symbol).foregroundStyle(.secondary).frame(width: 22)
                    Text(skill.title).font(.subheadline)
                    Spacer()
                    HStack(spacing: 6) {
                        ForEach(people, id: \.uuid) { p in
                            Button(p.name) { onPick(p) }
                                .font(.subheadline)
                                .buttonStyle(.borderless)
                                .tint(Color.ink)
                        }
                    }
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
