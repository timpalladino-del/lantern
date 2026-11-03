import Foundation
import StoreKit

/// The ladder. Free is one person and 50 items. Everything in the Toolkit is free on every plan.
enum Plan: Int, Comparable, CaseIterable {
    case free = 0, family6, family10, group50

    static func < (a: Plan, b: Plan) -> Bool { a.rawValue < b.rawValue }

    var productID: String? {
        switch self {
        case .free: return nil
        case .family6: return "io.kismetstudio.lantern.family6"
        case .family10: return "io.kismetstudio.lantern.family10"
        case .group50: return "io.kismetstudio.lantern.group50"
        }
    }

    init?(productID: String) {
        guard let p = Plan.allCases.first(where: { $0.productID == productID }) else { return nil }
        self = p
    }

    var title: String {
        switch self {
        case .free: return "Free"
        case .family6: return "Family 6"
        case .family10: return "Family 10"
        case .group50: return "Group 50"
        }
    }

    var maxPeople: Int {
        switch self {
        case .free: return 1
        case .family6: return 6
        case .family10, .group50: return 10
        }
    }

    var isPaid: Bool { self != .free }

    /// Fallback prices for when the App Store has not answered yet.
    var fallbackPrice: String {
        switch self {
        case .free: return "$0"
        case .family6: return "$12.99"
        case .family10: return "$19.99"
        case .group50: return "$49.99"
        }
    }

    /// The smallest plan that covers this many people in one house.
    static func needed(forPeople n: Int) -> Plan {
        if n <= 1 { return .free }
        if n <= 6 { return .family6 }
        return .family10
    }
}

/// Why the paywall is being shown. The headline changes with it.
enum PaywallReason: Identifiable, Equatable {
    case secondPerson(coveredDays: Double?)
    case itemLimit
    case moreThanSix
    case feature(String)
    case plans

    var id: String {
        switch self {
        case .secondPerson: return "secondPerson"
        case .itemLimit: return "itemLimit"
        case .moreThanSix: return "moreThanSix"
        case .feature(let f): return "feature-\(f)"
        case .plans: return "plans"
        }
    }
}

/// StoreKit 2. One subscription group, yearly, 7-day free trial on first purchase.
/// No account: the entitlement lives in the App Store receipt and is shared through Family Sharing.
@MainActor
@Observable
final class PlanStore {
    static let shared = PlanStore()
    static let freeItemLimit = 50
    /// Group 50 exists in App Store Connect but is not sold until group features ship.
    static let showsGroupTier = false

    private(set) var plan: Plan = .free
    private(set) var products: [Product] = []
    private(set) var trialEligible = true
    private(set) var isWorking = false
    var lastError: String?
    /// Set by a view that cannot present a sheet itself (it is dismissing). RootView presents it.
    var pendingPaywall: PaywallReason?

    private var updates: Task<Void, Never>?
    private var debugPlan: Plan?

    private init() {}

    func start() {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-plan"), i + 1 < args.count {
            debugPlan = ["free": .free, "family6": .family6, "family10": .family10, "group50": .group50][args[i + 1]]
        }
        #endif
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let t) = result { await t.finish() }
                await self?.refresh()
            }
        }
        Task {
            await loadProducts()
            await refresh()
        }
    }

    func loadProducts() async {
        let ids = Plan.allCases.compactMap(\.productID)
        do {
            let fetched = try await Product.products(for: ids)
            products = fetched.sorted { (Plan(productID: $0.id) ?? .free) < (Plan(productID: $1.id) ?? .free) }
            if let first = products.first?.subscription {
                trialEligible = await first.isEligibleForIntroOffer
            }
        } catch {
            lastError = "The App Store didn't answer. Check your connection and try again."
        }
    }

    /// Highest active entitlement wins.
    func refresh() async {
        var best = Plan.free
        for await result in Transaction.currentEntitlements {
            guard case .verified(let t) = result, t.revocationDate == nil else { continue }
            if let p = Plan(productID: t.productID), p > best { best = p }
        }
        if let debugPlan { best = debugPlan }
        plan = best
    }

    func product(for plan: Plan) -> Product? {
        products.first { $0.id == plan.productID }
    }

    func price(for plan: Plan) -> String {
        product(for: plan)?.displayPrice ?? plan.fallbackPrice
    }

    /// Returns true when the purchase went through (or was already owned).
    @discardableResult
    func purchase(_ target: Plan) async -> Bool {
        guard let product = product(for: target) else {
            lastError = "That plan isn't available right now."
            return false
        }
        isWorking = true
        defer { isWorking = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let t) = verification { await t.finish() }
                await refresh()
                return plan >= target
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    func restore() async {
        isWorking = true
        defer { isWorking = false }
        try? await AppStore.sync()
        await refresh()
    }

    // MARK: Gates

    func canAddItem(currentCount: Int) -> Bool {
        plan.isPaid || currentCount < PlanStore.freeItemLimit
    }

    func canAddItems(_ n: Int, currentCount: Int) -> Bool {
        plan.isPaid || currentCount + n <= PlanStore.freeItemLimit
    }

    /// People beyond the plan can still be added (readiness needs them); this says whether they are covered.
    func covers(peopleCount: Int) -> Bool {
        peopleCount <= plan.maxPeople
    }

    /// Per-person features (medications, profile links, cards) for the person at this position in the household.
    func coversPerson(at index: Int) -> Bool {
        index < plan.maxPeople
    }

    func reasonForAdding(personNumber n: Int) -> PaywallReason? {
        if covers(peopleCount: n) { return nil }
        return plan == .free ? .secondPerson(coveredDays: nil) : .moreThanSix
    }
}
