import Foundation
import SwiftData

/// First-launch defaults: locations and a household row. Nothing else; the user's data is theirs.
enum SeedData {
    @MainActor
    static func ensureDefaults(in context: ModelContext) {
        let locations = (try? context.fetch(FetchDescriptor<StorageLocation>())) ?? []
        if locations.isEmpty {
            for (index, pair) in StorageLocation.defaults.enumerated() {
                context.insert(StorageLocation(name: pair.0, symbol: pair.1, sortOrder: index))
            }
        }
        let households = (try? context.fetch(FetchDescriptor<Household>())) ?? []
        if households.isEmpty {
            context.insert(Household())
        }
        let contacts = (try? context.fetch(FetchDescriptor<EmergencyContact>())) ?? []
        if contacts.isEmpty {
            for (i, c) in EmergencyContact.defaults.enumerated() {
                context.insert(EmergencyContact(name: c.0, role: c.1, phone: c.2, notes: c.3, isBuiltIn: true, sortOrder: i))
            }
        }
        let plans = (try? context.fetch(FetchDescriptor<HouseholdPlan>())) ?? []
        if plans.isEmpty {
            context.insert(HouseholdPlan())
        }
        try? context.save()
    }

    /// Adds a starter pack's lines to a location, estimating dates from today.
    @MainActor
    static func apply(pack: StarterPack, to location: StorageLocation?, in context: ModelContext, library: ShelfLifeLibrary = .shared) {
        for line in pack.items {
            context.insert(makeItem(from: line, location: location, kit: nil, library: library))
        }
        try? context.save()
    }

    /// One template line as a real item, dated today with an estimated best-by when the library knows one.
    @discardableResult
    static func makeItem(from line: StarterPackItem, location: StorageLocation?, kit: Kit?, library: ShelfLifeLibrary = .shared) -> SupplyItem {
        let today = Date()
        let item = SupplyItem(name: line.name, category: SupplyCategory.from(line.category), quantity: line.quantity, unit: line.unit, location: location)
        item.purchaseDate = today
        item.servingsPerUnit = line.servingsPerUnit
        item.litersPerUnit = line.litersPerUnit
        item.kit = kit
        if let key = line.shelfLifeKey, let entry = library.entry(for: key) {
            item.shelfLifeKey = key
            if !entry.needsPrintedDate, let est = entry.estimate(from: today, opened: false, deepStorage: false) {
                item.expirationDate = est
                item.dateSource = .estimated
            }
        }
        return item
    }
}
