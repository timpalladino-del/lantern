import XCTest
@testable import Lantern

final class NutritionTests: XCTestCase {
    func testEmptyFactsAreNilOnTheItem() {
        let item = SupplyItem(name: "Beans", category: .food)
        XCTAssertNil(item.nutrition)
        item.nutrition = NutritionFacts(servingSize: "1/2 cup", calories: 110, proteinG: 7, sodiumMg: 400, source: "label")
        XCTAssertEqual(item.caloriesPerServing, 110)
        XCTAssertEqual(item.nutrition?.rows.first?.0, "Serving size")
        item.nutrition = nil
        XCTAssertNil(item.caloriesPerServing)
        XCTAssertEqual(item.nutritionSource, "")
    }

    func testCaloriesPerUnitFromServings() {
        let facts = NutritionFacts(calories: 110)
        XCTAssertEqual(facts.caloriesPerUnit(servings: 3.5), 385)
        XCTAssertNil(facts.caloriesPerUnit(servings: nil))
        XCTAssertNil(NutritionFacts().caloriesPerUnit(servings: 2))
    }

    func testProteinOnHandScalesWithQuantityAndServings() {
        let item = SupplyItem(name: "Tuna", category: .food, quantity: 10, unit: "can")
        item.servingsPerUnit = 2
        item.proteinGPerServing = 20
        XCTAssertEqual(item.totalProteinG, 400)
        item.category = .water
        XCTAssertNil(item.totalProteinG)
    }

    func testRowsFormatGramsAndMilligrams() {
        let facts = NutritionFacts(calories: 200, fatG: 1.5, sodiumMg: 480, proteinG: 8)
        let rows = Dictionary(uniqueKeysWithValues: facts.rows.map { ($0.0, $0.1) })
        XCTAssertEqual(rows["Calories"], "200")
        XCTAssertEqual(rows["Total fat"], "1.5 g")
        XCTAssertEqual(rows["Sodium"], "480 mg")
        XCTAssertEqual(rows["Protein"], "8 g")
    }
}
