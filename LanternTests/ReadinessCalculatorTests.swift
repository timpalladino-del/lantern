import XCTest
import SwiftData
@testable import Lantern

@MainActor
final class ReadinessCalculatorTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        container = try AppSchema.container(inMemory: true)
        context = ModelContext(container)
    }

    private func food(_ name: String, qty: Double, servings: Double, expires: Date? = nil) -> SupplyItem {
        let i = SupplyItem(name: name, category: .food, quantity: qty, unit: "can")
        i.servingsPerUnit = servings
        i.expirationDate = expires
        context.insert(i)
        return i
    }

    private func water(_ name: String, gallons: Double) -> SupplyItem {
        let i = SupplyItem(name: name, category: .water, quantity: gallons, unit: "gal")
        context.insert(i)
        return i
    }

    func testDaysOfSupplyForTwoPlaceholderAdults() {
        let household = Household(adults: 2, children: 0, pets: 0, targetDays: 14)
        context.insert(household)
        _ = food("Beans", qty: 16, servings: 2)          // 32 servings × 250 kcal = 8000 kcal → 2 days at 4000/day
        _ = water("Water", gallons: 8)                   // 8 gal → 4 days for 2 people
        let r = ReadinessCalculator.compute(items: fetch(), tasks: [], household: household)
        XCTAssertEqual(r.caloriesPerDay, 4000, accuracy: 0.01)
        XCTAssertEqual(r.foodDays, 2, accuracy: 0.01)
        XCTAssertTrue(r.foodIsAssumed)
        XCTAssertEqual(r.waterDays, 4, accuracy: 0.01)
        XCTAssertEqual(r.gaps.map(\.id), ["food", "water", "medicine"])
    }

    func testCaloriesPerUnitBeatsServings() {
        let household = Household(adults: 1, targetDays: 3)
        context.insert(household)
        let i = food("Rice", qty: 2, servings: 10)
        i.caloriesPerUnit = 1650
        let r = ReadinessCalculator.compute(items: fetch(), tasks: [], household: household)
        XCTAssertEqual(r.caloriesOnHand, 3300, accuracy: 0.01)
        XCTAssertFalse(r.foodIsAssumed)
    }

    func testRealPeopleDriveCalories() {
        let household = Household(targetDays: 3)
        context.insert(household)
        let adult = Person(name: "Sam", age: 40, weightKg: 80, heightCm: 180, sex: .male, activity: .light)
        adult.household = household
        context.insert(adult)
        let kid = Person(name: "Jo", age: 6)
        kid.household = household
        context.insert(kid)
        let baby = Person(name: "Bea", age: 0)
        baby.household = household
        context.insert(baby)
        try? context.save()
        // Mifflin-St Jeor: 10*80 + 6.25*180 - 5*40 + 5 = 1730 × 1.375 = 2378.75; child band 4-8 unspecified = 1450
        XCTAssertEqual(adult.dailyCalories, 2378.75, accuracy: 0.01)
        XCTAssertEqual(kid.dailyCalories, 1450, accuracy: 0.01)
        XCTAssertEqual(baby.dailyCalories, 0)
        let r = ReadinessCalculator.compute(items: [], tasks: [], household: household)
        XCTAssertEqual(r.caloriesPerDay, 3828.75, accuracy: 0.01)
        XCTAssertEqual(r.people, 3)
        XCTAssertEqual(r.infantCount, 1)
        XCTAssertTrue(r.gaps.contains { $0.id == "formula" })
    }

    func testMedicationDaysOfSupplyAndGap() {
        let household = Household(targetDays: 14)
        context.insert(household)
        let p = Person(name: "Sam", age: 40)
        p.household = household
        context.insert(p)
        let m = Medication(name: "Metformin", dose: "500 mg", dosesPerDay: 2, unitsPerDose: 1, unitsOnHand: 10, isCritical: true)
        m.person = p
        context.insert(m)
        try? context.save()
        XCTAssertEqual(m.daysOfSupply!, 5, accuracy: 0.01)
        let r = ReadinessCalculator.compute(items: [], tasks: [], household: household)
        XCTAssertEqual(r.medicineDays!, 5, accuracy: 0.01)
        XCTAssertTrue(r.gaps.contains { $0.id == "med-\(m.uuid.uuidString)" })
        XCTAssertFalse(r.gaps.contains { $0.id == "medicine" }, "a tracked medication counts as medicine")
    }

    func testGuidelineBands() {
        XCTAssertEqual(CalorieEstimator.guidelineCalories(age: 2, sex: .female, activity: .light), 1100)
        XCTAssertEqual(CalorieEstimator.guidelineCalories(age: 16, sex: .male, activity: .light), 2500)
        XCTAssertEqual(CalorieEstimator.guidelineCalories(age: 70, sex: .unspecified, activity: .sedentary), 1950 * 0.9, accuracy: 0.01)
        XCTAssertEqual(CalorieEstimator.dailyCalories(age: 0, weightKg: nil, heightCm: nil, sex: .female, activity: .light), 0)
    }

    func testExpiredAndEmptyStockIsExcluded() {
        let household = Household(adults: 1, targetDays: 3)
        context.insert(household)
        let past = Calendar.current.date(byAdding: .day, value: -10, to: Date())
        _ = food("Old soup", qty: 10, servings: 2, expires: past)
        _ = food("Empty", qty: 0, servings: 2)
        let r = ReadinessCalculator.compute(items: fetch(), tasks: [], household: household)
        XCTAssertEqual(r.caloriesOnHand, 0)
    }

    func testNoGapsWhenCovered() {
        let household = Household(adults: 1, children: 0, pets: 0, targetDays: 3)
        context.insert(household)
        _ = food("Rice", qty: 1, servings: 24)   // 6000 kcal ≥ 3 days × 2000
        _ = water("Water", gallons: 3)
        let med = SupplyItem(name: "First aid kit", category: .medicine)
        context.insert(med)
        let r = ReadinessCalculator.compute(items: fetch(), tasks: [], household: household)
        XCTAssertTrue(r.gaps.isEmpty, "\(r.gaps)")
    }

    func testPetsAddWater() {
        let h1 = Household(adults: 1, pets: 0); context.insert(h1)
        let h2 = Household(adults: 1, pets: 2); context.insert(h2)
        let noPets = ReadinessCalculator.compute(items: [water("W", gallons: 10)], tasks: [], household: h1)
        let pets = ReadinessCalculator.compute(items: [water("W2", gallons: 10)], tasks: [], household: h2)
        XCTAssertGreaterThan(noPets.waterDays, pets.waterDays)

        let h3 = Household(adults: 1); context.insert(h3)
        let dog = Pet(name: "Rex", species: .dog, weightKg: 30); dog.household = h3; context.insert(dog)
        try? context.save()
        let withDog = ReadinessCalculator.compute(items: [water("W3", gallons: 10)], tasks: [], household: h3)
        XCTAssertEqual(withDog.waterLitersPerDay, 3.785 + 1.8, accuracy: 0.01)
    }

    func testWaterUnitConversion() {
        let i = SupplyItem(name: "Bottles", category: .water, quantity: 2, unit: "L")
        XCTAssertEqual(i.totalLiters, 2, accuracy: 0.001)
        let g = SupplyItem(name: "Jug", category: .water, quantity: 1, unit: "gal")
        XCTAssertEqual(g.totalLiters, 3.785, accuracy: 0.001)
    }

    func testStatusLanguageThresholds() {
        let soon = SupplyItem(name: "Soup", category: .food)
        soon.expirationDate = Calendar.current.date(byAdding: .day, value: 10, to: Date())
        if case .soon(let d) = soon.status() { XCTAssertEqual(d, 10) } else { XCTFail() }

        let deep = SupplyItem(name: "Rice", category: .food)
        deep.isDeepStorage = true
        deep.expirationDate = Calendar.current.date(byAdding: .day, value: 100, to: Date())
        if case .soon = deep.status() {} else { XCTFail("deep storage should warn 180 days out") }

        let past = SupplyItem(name: "Beans", category: .food)
        past.expirationDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())
        if case .past(let d) = past.status() { XCTAssertEqual(d, 3) } else { XCTFail() }
    }

    func testMaintenanceDueMath() {
        let anchor = Calendar.current.date(byAdding: .day, value: -40, to: Date())!
        let t = MaintenanceTask(title: "Run", intervalDays: 30, anchorDate: anchor)
        XCTAssertTrue(t.isDue())
        XCTAssertEqual(t.daysUntilDue(), -10)
        t.lastDoneAt = Date()
        XCTAssertFalse(t.isDue())
        XCTAssertEqual(t.daysUntilDue(), 30)
    }

    private func fetch() -> [SupplyItem] {
        (try? context.fetch(FetchDescriptor<SupplyItem>())) ?? []
    }
}
