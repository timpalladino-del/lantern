import Foundation
import SwiftData

/// One line of inventory: "12 cans of black beans in the basement, best by March 2028."
@Model
final class SupplyItem {
    var uuid: UUID = UUID()
    var name: String = ""
    var brand: String = ""
    var categoryRaw: String = SupplyCategory.food.rawValue
    var quantity: Double = 1
    var unit: String = CommonUnit.each.rawValue
    var barcode: String?

    var purchaseDate: Date?
    var expirationDate: Date?
    var dateSourceRaw: String = DateSource.none.rawValue

    var isOpened: Bool = false
    var openedDate: Date?
    var isDeepStorage: Bool = false

    /// For water containers you fill yourself. Rotation is counted from here.
    var fillDate: Date?

    /// Key into the shelf-life library, when the item was matched to one.
    var shelfLifeKey: String?

    /// Readiness math. Food: calories per unit (preferred) or servings per unit. Water: litres per unit.
    var servingsPerUnit: Double?
    var caloriesPerUnit: Double?
    var litersPerUnit: Double?

    /// Nutrition facts per serving, as printed on the label or from the barcode lookup.
    var servingSizeText: String = ""
    var caloriesPerServing: Double?
    var proteinGPerServing: Double?
    var carbsGPerServing: Double?
    var fatGPerServing: Double?
    var fiberGPerServing: Double?
    var sugarGPerServing: Double?
    var sodiumMgPerServing: Double?
    /// "Open Food Facts", "label" or "" when nothing was entered.
    var nutritionSource: String = ""

    var notes: String = ""
    var lastCheckedAt: Date?
    var snoozedUntil: Date?

    @Attribute(.externalStorage)
    var photoData: Data?

    var location: StorageLocation?
    /// The go-bag or car kit this item is packed in, if any.
    var kit: Kit?

    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(name: String,
         category: SupplyCategory = .food,
         quantity: Double = 1,
         unit: String = CommonUnit.each.rawValue,
         location: StorageLocation? = nil) {
        self.uuid = UUID()
        self.name = name
        self.categoryRaw = category.rawValue
        self.quantity = quantity
        self.unit = unit
        self.location = location
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: Derived

    var category: SupplyCategory {
        get { SupplyCategory.from(categoryRaw) }
        set { categoryRaw = newValue.rawValue }
    }

    var dateSource: DateSource {
        get { DateSource(rawValue: dateSourceRaw) ?? .none }
        set { dateSourceRaw = newValue.rawValue }
    }

    var isOut: Bool { quantity <= 0 }

    /// Whole days until the expiration date. Negative when past. Nil when no date.
    func daysUntilExpiration(from now: Date = Date(), calendar: Calendar = .current) -> Int? {
        guard let exp = expirationDate else { return nil }
        let start = calendar.startOfDay(for: now)
        let end = calendar.startOfDay(for: exp)
        return calendar.dateComponents([.day], from: start, to: end).day
    }

    func status(on now: Date = Date(), calendar: Calendar = .current) -> ExpiryStatus {
        if let snooze = snoozedUntil, snooze > now { return .snoozed(until: snooze) }
        guard let days = daysUntilExpiration(from: now, calendar: calendar) else { return .noDate }
        if days < 0 { return .past(days: -days) }
        if days <= soonThresholdDays { return .soon(days: days) }
        return .fine(days: days)
    }

    /// How far ahead "soon" starts for this item. Deep storage gets a long runway.
    var soonThresholdDays: Int {
        if isDeepStorage { return 180 }
        switch category {
        case .medicine, .baby: return 60
        case .water: return 30
        default: return 30
        }
    }

    /// Readiness helpers
    static let assumedCaloriesPerServing: Double = 250

    var totalServings: Double {
        guard category == .food else { return 0 }
        return max(0, quantity) * (servingsPerUnit ?? 1)
    }

    /// Calories on hand. Uses the per-unit figure when known, else servings at an assumed 250 kcal each.
    var totalCalories: Double {
        guard category == .food else { return 0 }
        if let c = caloriesPerUnit { return max(0, quantity) * c }
        return totalServings * SupplyItem.assumedCaloriesPerServing
    }

    var caloriesAreAssumed: Bool { category == .food && caloriesPerUnit == nil }

    var nutrition: NutritionFacts? {
        get {
            let n = NutritionFacts(servingSize: servingSizeText, calories: caloriesPerServing, proteinG: proteinGPerServing,
                                   carbsG: carbsGPerServing, fatG: fatGPerServing, fiberG: fiberGPerServing,
                                   sugarG: sugarGPerServing, sodiumMg: sodiumMgPerServing, source: nutritionSource)
            return n.isEmpty ? nil : n
        }
        set {
            servingSizeText = newValue?.servingSize ?? ""
            caloriesPerServing = newValue?.calories
            proteinGPerServing = newValue?.proteinG
            carbsGPerServing = newValue?.carbsG
            fatGPerServing = newValue?.fatG
            fiberGPerServing = newValue?.fiberG
            sugarGPerServing = newValue?.sugarG
            sodiumMgPerServing = newValue?.sodiumMg
            nutritionSource = newValue?.source ?? ""
        }
    }

    /// Protein on hand across the whole quantity, when the label gave a figure.
    var totalProteinG: Double? {
        guard category == .food, let p = proteinGPerServing else { return nil }
        return max(0, quantity) * (servingsPerUnit ?? 1) * p
    }

    /// Pet food on the shelf: anything in the pet category that reads like food.
    var isPetFood: Bool {
        guard category == .pet else { return false }
        if let k = shelfLifeKey, k.hasPrefix("pet_food") { return true }
        let n = name.lowercased()
        return n.contains("food") || n.contains("kibble") || n.contains("chow") || n.contains("formula")
    }

    /// Typical calories per unit for pet food when the bag's own number is not entered.
    static func assumedPetFoodCalories(unit: String) -> Double {
        switch unit {
        case "lb": return 1600
        case "kg": return 3500
        case "oz": return 100
        case "can": return 400
        case "cup": return 350
        case "bag": return 24000   // a 15 lb bag
        case "pouch": return 100
        default: return 400
        }
    }

    var totalPetFoodCalories: Double {
        guard isPetFood else { return 0 }
        let per = caloriesPerUnit ?? SupplyItem.assumedPetFoodCalories(unit: unit)
        return max(0, quantity) * per
    }
    var petFoodCaloriesAreAssumed: Bool { isPetFood && caloriesPerUnit == nil }

    var totalLiters: Double {
        guard category == .water else { return 0 }
        let perUnit = litersPerUnit ?? CommonUnit(rawValue: unit)?.litersPerUnit ?? 0
        return max(0, quantity) * perUnit
    }

    func touch() { updatedAt = Date() }
}

/// The panel on the back of the package, per serving. Everything optional; most people fill in calories only.
struct NutritionFacts: Codable, Equatable {
    var servingSize: String = ""
    var calories: Double?
    var proteinG: Double?
    var carbsG: Double?
    var fatG: Double?
    var fiberG: Double?
    var sugarG: Double?
    var sodiumMg: Double?
    var source: String = ""

    var isEmpty: Bool {
        servingSize.isEmpty && calories == nil && proteinG == nil && carbsG == nil && fatG == nil && fiberG == nil && sugarG == nil && sodiumMg == nil
    }

    /// Calories for a whole unit when the serving count is known.
    func caloriesPerUnit(servings: Double?) -> Double? {
        guard let c = calories, let s = servings, s > 0 else { return nil }
        return (c * s).rounded()
    }

    /// Rows for a label-style panel: (name, value). Only what is known.
    var rows: [(String, String)] {
        var out: [(String, String)] = []
        if !servingSize.isEmpty { out.append(("Serving size", servingSize)) }
        if let c = calories { out.append(("Calories", "\(Int(c.rounded()))")) }
        if let v = fatG { out.append(("Total fat", NutritionFacts.grams(v))) }
        if let v = sodiumMg { out.append(("Sodium", "\(Int(v.rounded())) mg")) }
        if let v = carbsG { out.append(("Total carbohydrate", NutritionFacts.grams(v))) }
        if let v = fiberG { out.append(("Dietary fiber", NutritionFacts.grams(v))) }
        if let v = sugarG { out.append(("Sugars", NutritionFacts.grams(v))) }
        if let v = proteinG { out.append(("Protein", NutritionFacts.grams(v))) }
        return out
    }

    static func grams(_ v: Double) -> String { v == v.rounded() ? "\(Int(v)) g" : String(format: "%.1f g", v) }
}

/// What the UI says about an item's date. Language stays calm for food; firm for medicine.
enum ExpiryStatus: Equatable {
    case noDate
    case fine(days: Int)
    case soon(days: Int)
    case past(days: Int)
    case snoozed(until: Date)

    var sortRank: Int {
        switch self {
        case .past: return 0
        case .soon: return 1
        case .fine: return 2
        case .snoozed: return 3
        case .noDate: return 4
        }
    }

    var needsAttention: Bool {
        switch self {
        case .past, .soon: return true
        default: return false
        }
    }
}
