import Foundation
import SwiftData

/// Remembers a barcode so the second scan is one tap. Stays on the device.
@Model
final class ProductMemory {
    @Attribute(.unique) var barcode: String = ""
    var name: String = ""
    var brand: String = ""
    var categoryRaw: String = SupplyCategory.food.rawValue
    var unit: String = CommonUnit.each.rawValue
    var shelfLifeKey: String?
    var servingsPerUnit: Double?
    var caloriesPerUnit: Double?
    var litersPerUnit: Double?
    var nutritionJSON: String = ""
    var lastUsedAt: Date = Date()
    var useCount: Int = 0

    init(barcode: String, name: String, brand: String = "", category: SupplyCategory = .food, unit: String = CommonUnit.each.rawValue) {
        self.barcode = barcode
        self.name = name
        self.brand = brand
        self.categoryRaw = category.rawValue
        self.unit = unit
        self.lastUsedAt = Date()
        self.useCount = 0
    }

    var category: SupplyCategory {
        get { SupplyCategory.from(categoryRaw) }
        set { categoryRaw = newValue.rawValue }
    }

    var nutrition: NutritionFacts? {
        guard let d = nutritionJSON.data(using: .utf8), let n = try? JSONDecoder().decode(NutritionFacts.self, from: d), !n.isEmpty else { return nil }
        return n
    }

    func remember(from item: SupplyItem) {
        name = item.name
        brand = item.brand
        categoryRaw = item.categoryRaw
        unit = item.unit
        shelfLifeKey = item.shelfLifeKey
        servingsPerUnit = item.servingsPerUnit
        nutritionJSON = item.nutrition.flatMap { try? JSONEncoder().encode($0) }.map { String(decoding: $0, as: UTF8.self) } ?? ""
        caloriesPerUnit = item.caloriesPerUnit
        litersPerUnit = item.litersPerUnit
        lastUsedAt = Date()
        useCount += 1
    }
}
