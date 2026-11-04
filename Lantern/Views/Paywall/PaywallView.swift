import SwiftUI
import StoreKit

/// One sheet for every upgrade moment. Ink buttons, never amber. Never shown inside the Toolkit.
struct PaywallView: View {
    let reason: PaywallReason
    @Environment(\.dismiss) private var dismiss
    @State private var store = PlanStore.shared
    @State private var selected: Plan = .duo
    @State private var purchased = false

    private var offered: [Plan] {
        // Duo leads when one or two people are involved; Family leads once there are three.
        var plans: [Plan] = [.duo, .family6]
        switch reason {
        case .moreThanTwo: plans = [.family6, .family10]
        case .moreThanSix: plans = [.family10]
        case .plans, .feature: plans = [.duo, .family6, .family10]
        default: break
        }
        if PlanStore.showsGroupTier { plans.append(.group50) }
        return plans.filter { $0 > store.plan }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    bullets
                    VStack(spacing: 10) {
                        ForEach(offered, id: \.self) { plan in
                            PlanCard(plan: plan, price: store.price(for: plan), isSelected: selected == plan) { selected = plan }
                        }
                    }
                    cta
                    legal
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Not now") { dismiss() } }
            }
            .onAppear {
                if let first = offered.first { selected = first }
                if store.products.isEmpty { Task { await store.loadProducts() } }
            }
            .onChange(of: store.plan) { _, newPlan in
                if newPlan >= selected { purchased = true; dismiss() }
            }
            .sensoryFeedback(.success, trigger: purchased)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "lightbulb.max.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.glow)
                .symbolEffect(.bounce, options: .nonRepeating)
                .accessibilityHidden(true)
            Text(headline).font(.title.weight(.bold)).fixedSize(horizontal: false, vertical: true)
            Text(subhead).font(.body).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }

    private var headline: String {
        switch reason {
        case .secondPerson(let days?):
            let whole = Int(days.rounded(.down))
            return whole <= 0 ? "Lantern covers one person for free." : "Your household is covered for \(whole) day\(whole == 1 ? "" : "s")."
        case .secondPerson(nil): return "Lantern covers one person for free."
        case .itemLimit: return "You've tracked 50 items. That's a real pantry."
        case .moreThanTwo: return "Three or more in the house? Family has room."
        case .moreThanSix: return "More than six people? Family 10 has room."
        case .feature(let f): return "\(f) is part of Family."
        case .plans: return "Free until you need it."
        }
    }

    private var subhead: String {
        switch reason {
        case .secondPerson: return "Duo covers the two of you. Family covers the whole house. Either way: everyone's medications, a card you can hand to whoever is helping, and no item limit."
        case .itemLimit: return "Duo keeps going: unlimited items, a second person when you want one, and reminders for the gear that keeps you safe."
        case .moreThanTwo: return "Everything in Duo, for up to six people in one house. The App Store credits what is left on Duo."
        case .moreThanSix: return "Everything in Family 6, for up to ten people in one house."
        case .feature: return "One plan covers the whole house. Everything in the Toolkit stays free."
        case .plans: return "One plan covers the whole house. Everything in the Toolkit stays free, always."
        }
    }

    private var bullets: some View {
        VStack(alignment: .leading, spacing: 12) {
            PaywallBullet(symbol: "person.2.fill", text: "Everyone the plan covers, with medications and medication cards")
            PaywallBullet(symbol: "shippingbox.fill", text: "Unlimited supplies, not 50")
            PaywallBullet(symbol: "paperplane.fill", text: "Profile links, so family fills in their own details")
            PaywallBullet(symbol: "wrench.and.screwdriver.fill", text: "Reminders for the generator, alarms and extinguisher")
            PaywallBullet(symbol: "flashlight.on.fill", text: "The Toolkit stays free on every plan, always", muted: true)
        }
    }

    private var cta: some View {
        VStack(spacing: 10) {
            Button {
                Task { await store.purchase(selected) }
            } label: {
                HStack {
                    if store.isWorking { ProgressView().tint(.white) }
                    Text(store.trialEligible ? "Start 7-day free trial" : "Subscribe to \(selected.title)")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.accentColor)
            .disabled(store.isWorking || offered.isEmpty)

            Text(store.trialEligible
                 ? "Then \(store.price(for: selected)) a year. Cancel anytime in Settings before the trial ends and you pay nothing."
                 : "\(store.price(for: selected)) a year. Cancel anytime in Settings.")
                .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)

            if let err = store.lastError {
                Text(err).font(.footnote).foregroundStyle(Color.ember).multilineTextAlignment(.center)
            }

            Button("Restore purchases") { Task { await store.restore() } }
                .font(.footnote)
                .disabled(store.isWorking)
        }
    }

    private var legal: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Payment is charged to your Apple ID at confirmation. The subscription renews yearly unless cancelled at least 24 hours before the end of the current period. Manage or cancel in Settings → Apple ID → Subscriptions. Shared with your Apple Family Sharing group.")
            HStack(spacing: 14) {
                Link("Privacy", destination: Legal.privacy)
                Link("Terms", destination: Legal.terms)
            }
        }
        .font(.caption2)
        .foregroundStyle(.tertiary)
    }
}

enum Legal {
    static let privacy = URL(string: "https://kismetstudio.io/lantern/privacy")!
    static let terms = URL(string: "https://kismetstudio.io/lantern/terms")!
}

private struct PaywallBullet: View {
    let symbol: String
    let text: String
    var muted = false
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol).frame(width: 24).foregroundStyle(muted ? Color.secondary : Color.glow)
            Text(text).foregroundStyle(muted ? .secondary : .primary).fixedSize(horizontal: false, vertical: true)
        }
        .font(.subheadline)
    }
}

private struct PlanCard: View {
    let plan: Plan
    let price: String
    let isSelected: Bool
    let onTap: () -> Void

    private var detail: String {
        switch plan {
        case .duo: return "Two people in your house"
        case .family6: return "Up to 6 people in your house"
        case .family10: return "Up to 10 people in your house"
        case .group50: return "Up to 50 households, for organizers"
        case .free: return ""
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(plan.title).font(.headline)
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(price).font(.headline)
                    Text("per year").font(.caption2).foregroundStyle(.secondary)
                }
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    .padding(.leading, 6)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel("\(plan.title), \(price) per year, \(detail)")
    }
}

/// A list row that opens the paywall. Used wherever a paid feature is shown to a free household.
struct LockedRow: View {
    let title: String
    let reason: PaywallReason
    @State private var showPaywall = false
    var body: some View {
        Button { showPaywall = true } label: {
            Label(title, systemImage: "lock.fill").foregroundStyle(.primary)
        }
        .sheet(isPresented: $showPaywall) { PaywallView(reason: reason).tint(Color.accentColor) }
    }
}
