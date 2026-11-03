import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query private var items: [SupplyItem]
    @Query private var tasks: [MaintenanceTask]
    @Query private var medications: [Medication]

    @AppStorage(AppSettings.notificationsEnabled) private var notificationsEnabled = false
    @AppStorage(AppSettings.digestWeekday) private var digestWeekday = 1
    @AppStorage(AppSettings.digestHour) private var digestHour = 9
    @AppStorage(AppSettings.hasSeenWelcome) private var hasSeenWelcome = false
    @State private var showOnboarding = false
    @State private var incomingRoute: IncomingRoute?
    @State private var screenshotMedication: Medication?
    @State private var screenshotScrollTarget: String?

    enum IncomingRoute: Identifiable {
        case newProfile(String), importProfile(ProfileCard)
        var id: String {
            switch self {
            case .newProfile(let s): return "new-\(s)"
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
            SeedData.ensureDefaults(in: context)
            if !hasSeenWelcome { showOnboarding = true }
        }
        .sheet(isPresented: $showOnboarding, onDismiss: { hasSeenWelcome = true }) {
            OnboardingView()
        }
        .onOpenURL { url in
            guard let route = ProfileExchange.route(for: url) else { return }
            showOnboarding = false
            switch route {
            case .newProfile(let by): incomingRoute = .newProfile(by)
            case .importProfile(let card): incomingRoute = .importProfile(card)
            }
        }
        .sheet(item: $incomingRoute) { route in
            switch route {
            case .newProfile(let by): ProfileBuilderView(requestedBy: by).tint(Color.accentColor)
            case .importProfile(let card): ProfileImportView(card: card).tint(Color.accentColor)
            }
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

    /// Launch argument `-screenshot medication` opens the medication editor on a sample record so the
    /// screen can be captured without tapping through. Debug builds only.
    private func openScreenshotRoute() {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        // `-open lantern://...` routes a link without the simulator's "Open in Lantern?" dialog.
        if let o = args.firstIndex(of: "-open"), o + 1 < args.count, let url = URL(string: args[o + 1]), let route = ProfileExchange.route(for: url) {
            showOnboarding = false
            switch route {
            case .newProfile(let by): incomingRoute = .newProfile(by)
            case .importProfile(let card): incomingRoute = .importProfile(card)
            }
        }
        guard let i = args.firstIndex(of: "-screenshot"), i + 1 < args.count else { return }
        switch args[i + 1] {
        case "medication", "medication-middle", "medication-bottom":
            screenshotScrollTarget = ["medication-middle": "instructions", "medication-bottom": "notes"][args[i + 1]]
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
