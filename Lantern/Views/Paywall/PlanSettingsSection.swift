import SwiftUI

/// "Your plan" in Settings.
struct PlanSettingsSection: View {
    @State private var store = PlanStore.shared
    @State private var showPaywall = false

    var body: some View {
        Section {
            LabeledContent("Plan", value: store.plan.title)
            if store.plan.isPaid {
                Link("Manage subscription", destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
            } else {
                Button("See plans") { showPaywall = true }
            }
            Button("Restore purchases") { Task { await store.restore() } }
        } header: { Text("Your plan") } footer: {
            Text(store.plan.isPaid
                 ? "Covers up to \(store.plan.maxPeople) people in your house. Shared with your Apple Family Sharing group."
                 : "Free covers one person and 50 items. Everything in the Toolkit is free on every plan.")
        }
        .sheet(isPresented: $showPaywall) { PaywallView(reason: .plans).tint(Color.accentColor) }
    }
}
