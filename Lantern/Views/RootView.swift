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

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill") { HomeView().tint(Color.accentColor) }
            Tab("Supplies", systemImage: "shippingbox.fill") { SuppliesListView().tint(Color.accentColor) }
            Tab("Equipment", systemImage: "wrench.and.screwdriver.fill") { EquipmentListView().tint(Color.accentColor) }
            Tab("Ready", systemImage: "checkmark.shield.fill") { ReadinessView().tint(Color.accentColor) }
            Tab("Settings", systemImage: "gearshape.fill") { SettingsView().tint(Color.accentColor) }
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
