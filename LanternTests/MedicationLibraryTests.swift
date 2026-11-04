import XCTest
@testable import Lantern

final class MedicationLibraryTests: XCTestCase {
    let lib = MedicationLibrary.shared

    func testLoads() {
        XCTAssertGreaterThan(lib.entries.count, 150)
    }

    func testPrefixAndBrand() {
        XCTAssertEqual(lib.search("metfor").first?.generic, "Metformin")
        XCTAssertEqual(lib.search("lipitor").first?.generic, "Atorvastatin")
        XCTAssertEqual(lib.search("Zoloft").first?.generic, "Sertraline")
    }

    func testMisspellings() {
        XCTAssertEqual(lib.search("amlodapine").first?.generic, "Amlodipine")
        XCTAssertEqual(lib.search("lisinapril").first?.generic, "Lisinopril")
        XCTAssertEqual(lib.search("gabapentine").first?.generic, "Gabapentin")
        XCTAssertEqual(lib.search("levothyroxin").first?.generic, "Levothyroxine")
    }

    func testPurposeSearch() {
        XCTAssertTrue(lib.search("blood pressure").contains { $0.generic == "Lisinopril" })
        XCTAssertTrue(lib.search("inhaler").contains { $0.generic == "Albuterol inhaler" })
    }

    func testEmptyQueryListsAlphabetically() {
        let r = lib.search("")
        XCTAssertFalse(r.isEmpty)
        XCTAssertEqual(r.map(\.generic), r.map(\.generic).sorted())
    }
}
