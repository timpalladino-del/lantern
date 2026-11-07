import Foundation
import SwiftData

/// A physical place supplies live: pantry, basement shelf, car, go-bag.
/// "If you can't walk to an item from its record, the inventory isn't useful."
@Model
final class StorageLocation {
    var uuid: UUID = UUID()
    var name: String = ""
    var symbol: String = "shippingbox.fill"
    var sortOrder: Int = 0
    var createdAt: Date = Date()
    /// "Top shelf, left of the water heater." The line that gets someone to the item in the dark.
    var notes: String = ""
    /// A street address or a landmark for a place that is not the house.
    var address: String = ""
    /// Optional position, for a cabin, a storage unit, a cache, a boat.
    var latitude: Double?
    var longitude: Double?
    @Attribute(.externalStorage) var photo: Data?

    @Relationship(deleteRule: .nullify, inverse: \SupplyItem.location)
    var items: [SupplyItem] = []

    @Relationship(deleteRule: .nullify, inverse: \Equipment.location)
    var equipment: [Equipment] = []

    init(name: String, symbol: String = "shippingbox.fill", sortOrder: Int = 0) {
        self.uuid = UUID()
        self.name = name
        self.symbol = symbol
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }

    var point: GeoPoint? {
        guard let la = latitude, let lo = longitude else { return nil }
        let p = GeoPoint(latitude: la, longitude: lo)
        return p.isValid ? p : nil
    }

    var isAwayFromHome: Bool { !address.isEmpty || point != nil }

    static let defaults: [(String, String)] = [
        ("Kitchen pantry", "cabinet.fill"),
        ("Basement or garage shelf", "shippingbox.fill"),
        ("Go-bag", "backpack.fill"),
        ("Car", "car.fill"),
        ("Medicine cabinet", "cross.case.fill")
    ]
}
