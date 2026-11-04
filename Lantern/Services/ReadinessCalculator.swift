import Foundation

/// Days-of-supply math against Red Cross and CDC targets, in calories per person. Calm numbers, no scores.
struct ReadinessReport: Equatable {
    struct Gap: Equatable, Identifiable {
        let id: String
        let title: String
        let detail: String
        let shoppingName: String
        let shoppingQuantity: Double
        let shoppingUnit: String
    }

    struct MedicationStatus: Equatable, Identifiable {
        let id: UUID
        let personName: String
        let name: String
        let daysOfSupply: Double?
        let isCritical: Bool
    }

    let targetDays: Int
    let people: Int
    let pets: Int

    let caloriesPerDay: Double
    let caloriesOnHand: Double
    let foodDays: Double
    let foodIsAssumed: Bool          // true when any food item has no calorie figure
    let waterLitersPerDay: Double
    var petFoodKcalPerDay: Double = 0
    var petFoodCalories: Double = 0
    var petFoodDays: Double = 0
    var petFoodIsAssumed: Bool = false
    var petFoodIsEstimated: Bool = false
    var petFoodFraction: Double { targetDays == 0 ? 1 : min(1, petFoodDays / Double(targetDays)) }
    let waterLiters: Double
    let waterDays: Double

    let medications: [MedicationStatus]
    let medicineItemsNeedingAttention: Int
    let itemsNeedingAttention: Int
    let tasksDue: Int
    let infantCount: Int

    let gaps: [Gap]

    static let litersPerPersonPerDay: Double = 3.785   // 1 US gallon, CDC/Ready.gov

    var foodFraction: Double { targetDays == 0 ? 1 : min(1, foodDays / Double(targetDays)) }
    var waterFraction: Double { targetDays == 0 ? 1 : min(1, waterDays / Double(targetDays)) }

    /// Shortest medication supply, if any medication is tracked.
    var medicineDays: Double? {
        medications.compactMap(\.daysOfSupply).min()
    }
    var medicineFraction: Double {
        guard let d = medicineDays, targetDays > 0 else { return 1 }
        return min(1, d / Double(targetDays))
    }
}

enum ReadinessCalculator {
    static func compute(items: [SupplyItem],
                        tasks: [MaintenanceTask],
                        household: Household,
                        now: Date = Date()) -> ReadinessReport {
        let people = household.peopleCount
        let pets = household.petCount
        let target = max(1, household.targetDays)

        // Only count stock that is not past its date and not used up.
        let usable = items.filter { item in
            guard item.quantity > 0 else { return false }
            if case .past = item.status(on: now) { return false }
            return true
        }

        let calories = usable.reduce(0.0) { $0 + $1.totalCalories }
        let assumed = usable.contains { $0.caloriesAreAssumed && $0.quantity > 0 }
        let liters = usable.reduce(0.0) { $0 + $1.totalLiters }

        let caloriesPerDay = max(1, household.caloriesPerDay)
        let petWater = household.petList.isEmpty
            ? Double(pets) * 1.0
            : household.petList.reduce(0.0) { $0 + $1.waterLitersPerDay }
        let litersPerDay = Double(people) * ReadinessReport.litersPerPersonPerDay + petWater

        let foodDays = calories / caloriesPerDay
        let waterDays = litersPerDay > 0 ? liters / litersPerDay : 0

        let medicineItems = items.filter { $0.category == .medicine }
        let medicineAttention = medicineItems.filter { $0.status(on: now).needsAttention }.count
        let attention = items.filter { $0.status(on: now).needsAttention }.count
        let due = tasks.filter { $0.isDue(on: now) }.count

        let medStatuses: [ReadinessReport.MedicationStatus] = household.sortedPeople.flatMap { person in
            person.medications.map { m in
                ReadinessReport.MedicationStatus(id: m.uuid, personName: person.name, name: m.name,
                                                  daysOfSupply: m.daysOfSupply, isCritical: m.isCritical)
            }
        }

        var gaps: [ReadinessReport.Gap] = []

        let foodShort = caloriesPerDay * Double(target) - calories
        if foodShort > 0 {
            let cans = Int((foodShort / 350).rounded(.up))  // a can of beans or soup is roughly 350 kcal
            gaps.append(.init(
                id: "food",
                title: "Food: \(formatDays(foodDays)) of \(target) days",
                detail: "About \(Int(foodShort.rounded())) more calories, roughly \(cans) cans, or the equivalent in rice, pasta, and peanut butter.",
                shoppingName: "Shelf-stable food to close the gap",
                shoppingQuantity: Double(cans),
                shoppingUnit: CommonUnit.can.rawValue))
        }

        let waterShortLiters = litersPerDay * Double(target) - liters
        if waterShortLiters > 0 {
            let gallons = Int((waterShortLiters / 3.785).rounded(.up))
            gaps.append(.init(
                id: "water",
                title: "Water: \(formatDays(waterDays)) of \(target) days",
                detail: "About \(gallons) more gallons. One gallon per person per day, plus a little for pets.",
                shoppingName: "Water",
                shoppingQuantity: Double(gallons),
                shoppingUnit: CommonUnit.gal.rawValue))
        }

        for m in medStatuses {
            guard let days = m.daysOfSupply, days < Double(target) else { continue }
            let short = Double(target) - days
            gaps.append(.init(
                id: "med-\(m.id.uuidString)",
                title: "\(m.name) for \(m.personName): \(formatDays(days)) of \(target)",
                detail: m.isCritical
                    ? "Critical. Ask the pharmacist about an early refill or a vacation supply."
                    : "About \(Int(short.rounded(.up))) more days' worth to reach your goal.",
                shoppingName: "\(m.name) (\(m.personName))",
                shoppingQuantity: 1,
                shoppingUnit: "refill"))
        }

        let infants = household.infants.count
        if infants > 0, !items.contains(where: { $0.shelfLifeKey == "infant_formula" || $0.name.lowercased().contains("formula") }) {
            gaps.append(.init(
                id: "formula",
                title: "No infant formula logged",
                detail: "A baby under one needs formula or stored milk counted separately. Add what you have.",
                shoppingName: "Infant formula",
                shoppingQuantity: 1,
                shoppingUnit: CommonUnit.each.rawValue))
        }

        if medicineItems.isEmpty && medStatuses.isEmpty {
            gaps.append(.init(
                id: "medicine",
                title: "No medicine or first aid logged",
                detail: "Add your first aid kit, and any daily medication under each person.",
                shoppingName: "First aid kit",
                shoppingQuantity: 1,
                shoppingUnit: CommonUnit.kit.rawValue))
        }

        // Pet food
        let petKcalPerDay = household.petList.reduce(0.0) { $0 + $1.foodKcalPerDay }
        let petFood = usable.reduce(0.0) { $0 + $1.totalPetFoodCalories }
        let petFoodDays = petKcalPerDay > 0 ? petFood / petKcalPerDay : 0
        if petKcalPerDay > 0 {
            let short = petKcalPerDay * Double(target) - petFood
            if short > 0 {
                let pounds = Int((short / 1600).rounded(.up))
                gaps.append(.init(id: "petfood", title: "Pet food: \(formatDays(petFoodDays)) of \(target) days",
                                  detail: "About \(pounds) more pounds of dry food, or the equivalent in cans. Shelters often take pets only with food and records.",
                                  shoppingName: "Pet food", shoppingQuantity: Double(pounds), shoppingUnit: "lb"))
            }
        }

        var report = ReadinessReport(
            targetDays: target, people: people, pets: pets,
            caloriesPerDay: caloriesPerDay, caloriesOnHand: calories, foodDays: foodDays, foodIsAssumed: assumed,
            waterLitersPerDay: litersPerDay, waterLiters: liters, waterDays: waterDays,
            medications: medStatuses, medicineItemsNeedingAttention: medicineAttention,
            itemsNeedingAttention: attention, tasksDue: due, infantCount: infants,
            gaps: gaps)
        report.petFoodKcalPerDay = petKcalPerDay
        report.petFoodCalories = petFood
        report.petFoodDays = petFoodDays
        report.petFoodIsAssumed = usable.contains { $0.petFoodCaloriesAreAssumed }
        report.petFoodIsEstimated = household.petList.contains { $0.foodIsEstimated }
        return report
    }

    static func formatDays(_ days: Double) -> String {
        if days >= 10 { return "\(Int(days.rounded())) days" }
        if days >= 1 { return String(format: "%.1f days", days) }
        if days <= 0 { return "0 days" }
        return "under a day"
    }
}
