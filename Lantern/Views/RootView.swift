import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query private var items: [SupplyItem]
    @Query private var tasks: [MaintenanceTask]
    @Query private var medications: [Medication]
    @Query private var households: [Household]
    @State private var plan = PlanStore.shared
    @State private var paywallReason: PaywallReason?

    @AppStorage(AppSettings.notificationsEnabled) private var notificationsEnabled = false
    @AppStorage(AppSettings.digestWeekday) private var digestWeekday = 1
    @AppStorage(AppSettings.digestHour) private var digestHour = 9
    @AppStorage(AppSettings.hasSeenWelcome) private var hasSeenWelcome = false
    @State private var showOnboarding = false
    @State private var incomingRoute: IncomingRoute?
    @State private var screenshotMedication: Medication?
    @State private var screenshotSheet: ScreenshotSheet?

    enum ScreenshotSheet: String, Identifiable {
        case outage, kit, medcard, plan, household, person, item, games, texts, settings
        case headsup, trivia, hangman, fourinarow, tictactoe, draw, wyr, twenty, story, hunt, puppets, memory, simon, first, rps, number, dice
        var id: String { rawValue }
    }
    @State private var screenshotScrollTarget: String?

    enum IncomingRoute: Identifiable, Equatable {
        case newProfile(String, String, String), importProfile(ProfileCard)
        var id: String {
            switch self {
            case .newProfile(let s, let f, let h): return "new-\(s)-\(f)-\(h)"
            case .importProfile(let c): return "import-\(c.name)-\(c.createdAt.timeIntervalSince1970)"
            }
        }
    }
    /// Launch argument `-tab <name>` opens a tab directly (used for screenshots: `xcrun simctl launch ... -tab Toolkit`).
    @State private var selectedTab: String = {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-tab"), i + 1 < args.count { return args[i + 1] }
        return "Home"
    }()

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: "Home") { HomeView().tint(Color.accentColor) }
            Tab("Supplies", systemImage: "shippingbox.fill", value: "Supplies") { SuppliesListView().tint(Color.accentColor) }
            Tab("Equipment", systemImage: "wrench.and.screwdriver.fill", value: "Equipment") { EquipmentListView().tint(Color.accentColor) }
            Tab("Ready", systemImage: "checkmark.shield.fill", value: "Ready") { ReadinessView().tint(Color.accentColor) }
            Tab("Toolkit", systemImage: "flashlight.on.fill", value: "Toolkit") { ToolkitView().tint(Color.accentColor) }
        }
        .tint(Color.glow)
        .task {
            PlanStore.shared.start()
            SeedData.ensureDefaults(in: context)
            if !hasSeenWelcome { showOnboarding = true }
        }
        .onChange(of: plan.pendingPaywall) { _, _ in presentPendingPaywall() }
        .onChange(of: showOnboarding) { _, shown in if !shown { presentPendingPaywall() } }
        .onChange(of: incomingRoute) { _, route in if route == nil { presentPendingPaywall() } }
        .sheet(item: $paywallReason) { PaywallView(reason: $0).tint(Color.accentColor) }
        .sheet(isPresented: $showOnboarding, onDismiss: { hasSeenWelcome = true }) {
            OnboardingView()
        }
        .onOpenURL { url in
            guard let route = ProfileExchange.route(for: url) else { return }
            showOnboarding = false
            switch route {
            case .newProfile(let by, let f, let h): incomingRoute = .newProfile(by, f, h)
            case .importProfile(let card): incomingRoute = .importProfile(card)
            }
        }
        .sheet(item: $incomingRoute) { route in
            switch route {
            case .newProfile(let by, let f, let h): ProfileBuilderView(requestedBy: by, forName: f, householdToken: h).tint(Color.accentColor)
            case .importProfile(let card): ProfileImportView(card: card).tint(Color.accentColor)
            }
        }
        .fullScreenCover(item: $screenshotSheet) { which in
            NavigationStack {
                switch which {
                case .outage: OutageView()
                case .kit: if let k = try? context.fetch(FetchDescriptor<Kit>()).first { KitDetailView(kit: k) }
                case .medcard: MedicationCardView()
                case .plan: PlanView()
                case .household: if let h = households.first { HouseholdView(household: h).navigationTitle("Household") }
                case .person:
                    if let h = households.first, let p = h.sortedPeople.first(where: { $0.name == "Maria" }) ?? h.sortedPeople.first {
                        PersonEditView(household: h, person: p)
                    }
                case .item:
                    if let it = (try? context.fetch(FetchDescriptor<SupplyItem>()))?.first(where: { $0.name == "Black beans" }) ?? items.first {
                        ItemDetailView(item: it)
                    }
                case .settings: SettingsView()
                case .games: GamesView()
                case .texts: StatusTextsView()
                case .headsup: WordRoundView(mode: .headsUp)
                case .trivia: TriviaView()
                case .hangman: HangmanView()
                case .fourinarow: FourInARowView()
                case .tictactoe: TicTacToeView()
                case .draw: DrawGuessView()
                case .wyr: WouldYouRatherView()
                case .twenty: TwentyQuestionsView()
                case .story: StoryChainView()
                case .hunt: ScavengerHuntView()
                case .puppets: ShadowPuppetsView()
                case .memory: MemoryMatchView()
                case .simon: SimonView()
                case .first: WhoGoesFirstView()
                case .rps: RockPaperScissorsView()
                case .number: NumberGuessView()
                case .dice: DiceCardsView()
                }
            }
            .tint(Color.accentColor)
        }
        .sheet(item: $screenshotMedication) { m in
            if let p = m.person { MedicationEditView(person: p, medication: m, scrollTarget: screenshotScrollTarget).tint(Color.accentColor) }
        }
        .task { openScreenshotRoute() }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .background, notificationsEnabled else { return }
            let snapshotItems = items
            let snapshotTasks = tasks
            let snapshotMeds = medications
            Task { @MainActor in
                await NotificationScheduler.shared.reschedule(items: snapshotItems, tasks: snapshotTasks, medications: snapshotMeds,
                                                               digestWeekday: digestWeekday, digestHour: digestHour)
            }
        }
    }

    /// A sheet that is dismissing cannot present the paywall, so views leave a reason on the store and we
    /// present it once nothing else is on screen.
    private func presentPendingPaywall() {
        guard let reason = plan.pendingPaywall, !showOnboarding, incomingRoute == nil, paywallReason == nil else { return }
        var enriched = reason
        if case .secondPerson(nil) = reason, let h = households.first {
            let report = ReadinessCalculator.compute(items: items, tasks: tasks, household: h, now: Date())
            enriched = .secondPerson(coveredDays: min(report.foodDays, report.waterDays))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            plan.pendingPaywall = nil
            paywallReason = enriched
        }
    }

    /// Launch argument `-screenshot medication` opens the medication editor on a sample record so the
    /// screen can be captured without tapping through. Debug builds only.
    private func openScreenshotRoute() {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-demo") { SeedData.demo(in: context) }
        // `-open lantern://...` routes a link without the simulator's "Open in Lantern?" dialog.
        if let o = args.firstIndex(of: "-open"), o + 1 < args.count, let url = URL(string: args[o + 1]), let route = ProfileExchange.route(for: url) {
            showOnboarding = false
            switch route {
            case .newProfile(let by, let f, let h): incomingRoute = .newProfile(by, f, h)
            case .importProfile(let card): incomingRoute = .importProfile(card)
            }
        }
        guard let i = args.firstIndex(of: "-screenshot"), i + 1 < args.count else { return }
        switch args[i + 1] {
        case let name where ScreenshotSheet(rawValue: name) != nil:
            screenshotSheet = ScreenshotSheet(rawValue: name)
        case "paywall":
            paywallReason = .secondPerson(coveredDays: 4)
        case "paywall-items":
            paywallReason = .itemLimit
        case "paywall-three":
            paywallReason = .moreThanTwo
        case "paywall-plans":
            paywallReason = .plans
        case "medication", "medication-middle", "medication-bottom":
            screenshotScrollTarget = ["medication-middle": "instructions", "medication-bottom": "notes"][args[i + 1]]
            if let demoMed = (try? context.fetch(FetchDescriptor<Medication>()))?.first(where: { $0.name == "Metformin" && $0.person?.name == "Maria" }) {
                screenshotMedication = demoMed
                return
            }
            let household = (try? context.fetch(FetchDescriptor<Household>()))?.first ?? Household()
            let person = Person(name: "Maria", age: 42, weightKg: 68, heightCm: 165, sex: .female, activity: .light)
            person.allergies = "Penicillin"
            person.household = household
            context.insert(person)
            let m = Medication(name: "Metformin", dose: "500 mg", dosesPerDay: 2, unitsPerDose: 1, unitsOnHand: 48, isCritical: false)
            m.purpose = "Type 2 diabetes"
            m.scheduleMinutes = [8 * 60, 20 * 60]
            m.instructionKeys = [MedicationInstruction.withFood.rawValue, MedicationInstruction.noAlcohol.rawValue, MedicationInstruction.lowSugar.rawValue]
            m.prescriber = "Dr. Alvarez"
            m.prescriberPhone = "(305) 555-0142"
            m.pharmacy = "CVS, Main St"
            m.pharmacyPhone = "(305) 555-0199"
            m.rxNumber = "7731904"
            m.remindersEnabled = true
            m.person = person
            context.insert(m)
            try? context.save()
            screenshotMedication = m
        default: break
        }
        #endif
    }
}
