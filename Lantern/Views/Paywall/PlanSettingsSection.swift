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
            }
            if store.plan < .family10 {
                Button(store.plan.isPaid ? "Move up a plan" : "See plans") { showPaywall = true }
            }
            Button("Restore purchases") { Task { await store.restore() } }
        } header: { Text("Your plan") } footer: {
            Text(store.plan.isPaid
                 ? "\(store.plan.peopleLine). Shared with your Apple Family Sharing group."
                 : "\(store.plan.peopleLine). Everything in the Toolkit is free on every plan.")
        }
        .sheet(isPresented: $showPaywall) { PaywallView(reason: .plans).tint(Color.ink) }
    }
}
