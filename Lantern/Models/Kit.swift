import Foundation
import SwiftData

enum KitKind: String, CaseIterable, Codable, Identifiable {
    case goBag, car, pet, work, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .goBag: return "Go-bag"
        case .car: return "Car kit"
        case .pet: return "Pet bag"
        case .work: return "Work or school"
        case .other: return "Other"
        }
    }
    var symbol: String {
        switch self {
        case .goBag: return "backpack.fill"
        case .car: return "car.fill"
        case .pet: return "pawprint.fill"
        case .work: return "briefcase.fill"
        case .other: return "bag.fill"
        }
    }
}

/// A container you can pick up and leave with. Items in a kit are ordinary supplies that also belong here,
/// so they count toward readiness and get the same expiration reminders.
@Model
final class Kit {
    var uuid: UUID = UUID()
    var name: String = ""
    var kindRaw: String = KitKind.goBag.rawValue
    var templateKey: String?            // which library template it was started from, for the "missing" list
    var notes: String = ""              // "Hall closet, top shelf"
    var lastCheckedAt: Date?
    var sortOrder: Int = 0
    var createdAt: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \SupplyItem.kit)
    var items: [SupplyItem] = []

    init(name: String, kind: KitKind = .goBag, templateKey: String? = nil) {
        self.uuid = UUID()
        self.name = name
        self.kindRaw = kind.rawValue
        self.templateKey = templateKey
        self.createdAt = Date()
    }

    var kind: KitKind {
        get { KitKind(rawValue: kindRaw) ?? .other }
        set { kindRaw = newValue.rawValue }
    }

    var activeItems: [SupplyItem] { items.filter { $0.quantity > 0 } }

    /// Kits want a look every six months (Ready.gov: "re-think your needs every year, replace expired items").
    var checkIsDue: Bool {
        guard let last = lastCheckedAt else { return true }
        return Date().timeIntervalSince(last) > 182 * 86400
    }

    func attentionCount(on date: Date = Date()) -> Int {
        activeItems.filter { $0.status(on: date).needsAttention }.count
    }
}
