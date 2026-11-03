import XCTest
@testable import Lantern

@MainActor
final class PlanTests: XCTestCase {
    func testLadderOrderAndLimits() {
        XCTAssertTrue(Plan.free < Plan.family6)
        XCTAssertTrue(Plan.family6 < Plan.family10)
        XCTAssertTrue(Plan.family10 < Plan.group50)
        XCTAssertEqual(Plan.free.maxPeople, 1)
        XCTAssertEqual(Plan.family6.maxPeople, 6)
        XCTAssertEqual(Plan.family10.maxPeople, 10)
        XCTAssertEqual(Plan.group50.maxPeople, 10)
    }

    func testNeededPlanForPeople() {
        XCTAssertEqual(Plan.needed(forPeople: 1), .free)
        XCTAssertEqual(Plan.needed(forPeople: 2), .family6)
        XCTAssertEqual(Plan.needed(forPeople: 6), .family6)
        XCTAssertEqual(Plan.needed(forPeople: 7), .family10)
    }

    func testProductIDsRoundTrip() {
        for p in Plan.allCases where p != .free {
            XCTAssertEqual(Plan(productID: p.productID!), p)
        }
        XCTAssertNil(Plan(productID: "io.kismetstudio.lantern.nope"))
    }

    func testFreeGates() {
        let store = PlanStore.shared   // fresh process: no entitlements, so Free
        XCTAssertEqual(store.plan, .free)
        XCTAssertTrue(store.canAddItem(currentCount: 49))
        XCTAssertFalse(store.canAddItem(currentCount: 50))
        XCTAssertTrue(store.canAddItems(10, currentCount: 40))
        XCTAssertFalse(store.canAddItems(11, currentCount: 40))
        XCTAssertTrue(store.covers(peopleCount: 1))
        XCTAssertFalse(store.covers(peopleCount: 2))
        XCTAssertTrue(store.coversPerson(at: 0))
        XCTAssertFalse(store.coversPerson(at: 1))
        XCTAssertNil(store.reasonForAdding(personNumber: 1))
        XCTAssertEqual(store.reasonForAdding(personNumber: 2), .secondPerson(coveredDays: nil))
    }
}
