import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query private var items: [SupplyItem]
    @Query private var tasks: [MaintenanceTask]

    @AppStorage(AppSettings.notificationsEnabled) private var notificationsEnabled = false
    @AppStorage(AppSettings.digestWeekday) private var digestWeekday = 1
    @AppStorage(AppSettings.digestHour) private var digestHour = 9
    @AppStorage(AppSettings.hasSeenWelcome) private var hasSeenWelcome = false
    @State private var showOnboarding = false
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
        .onChange(of: scenePhase) { _, phase in
            guard phase == .background, notificationsEnabled else { return }
            let snapshotItems = items
            let snapshotTasks = tasks
            Task { @MainActor in
                await NotificationScheduler.shared.reschedule(items: snapshotItems, tasks: snapshotTasks,
                                                               digestWeekday: digestWeekday, digestHour: digestHour)
            }
        }
    }
}
