import XCTest
@testable import Lantern

final class MedicationTests: XCTestCase {
    func testScheduleSummaryFallsBackToCountWhenNoTimes() {
        let m = Medication(name: "Metformin", dosesPerDay: 2)
        XCTAssertEqual(m.scheduleSummary, "2 times a day")
        m.dosesPerDay = 1
        XCTAssertEqual(m.scheduleSummary, "Once a day")
        m.dosesPerDay = 0
        XCTAssertEqual(m.scheduleSummary, "As needed")
    }

    func testScheduleSummaryListsTimesInOrder() {
        let m = Medication(name: "Metformin", dosesPerDay: 2)
        m.scheduleMinutes = [20 * 60, 8 * 60]
        let summary = m.scheduleSummary
        XCTAssertTrue(summary.contains("8"), summary)
        XCTAssertTrue(summary.firstIndex(of: "8")! < summary.lastIndex(of: "8")!, summary)
        XCTAssertEqual(summary.components(separatedBy: ", ").count, 2)
    }

    func testCardLineReadsLikeALabel() {
        let m = Medication(name: "Metformin", dose: "500 mg", dosesPerDay: 2, unitsPerDose: 1, unitsOnHand: 60)
        m.scheduleMinutes = [8 * 60, 20 * 60]
        m.instructionKeys = [MedicationInstruction.withFood.rawValue, MedicationInstruction.noAlcohol.rawValue]
        let line = m.cardLine
        XCTAssertTrue(line.hasPrefix("Metformin 500 mg, 1 tablet at "), line)
        XCTAssertTrue(line.hasSuffix("Take with food. Avoid alcohol."), line)
        XCTAssertEqual(m.daysOfSupply, 30)
    }

    func testUnknownInstructionKeysAreIgnored() {
        let m = Medication(name: "X")
        m.instructionKeys = ["withFood", "notARealKey"]
        XCTAssertEqual(m.instructions, [.withFood])
    }

    func testEveryInstructionHasTitleAndSymbol() {
        for i in MedicationInstruction.allCases {
            XCTAssertFalse(i.title.isEmpty)
            XCTAssertFalse(i.symbol.isEmpty)
        }
        XCTAssertFalse(MedicationInstruction.all(of: .warning).isEmpty)
        XCTAssertFalse(MedicationInstruction.all(of: .howToTake).isEmpty)
    }

    func testCardTextIncludesPersonAndWarnings() {
        let p = Person(name: "Maria")
        p.allergies = "penicillin"
        let m = Medication(name: "Lisinopril", dose: "10 mg", dosesPerDay: 1)
        m.instructionKeys = [MedicationInstruction.noNSAIDs.rawValue]
        m.pharmacy = "CVS Main St"
        p.medications = [m]
        let text = MedicationCardView.cardText(for: [p])
        XCTAssertTrue(text.contains("MARIA"))
        XCTAssertTrue(text.contains("Lisinopril 10 mg"))
        XCTAssertTrue(text.contains("Avoid: Do not take with ibuprofen or aspirin"))
        XCTAssertTrue(text.contains("Pharmacy: CVS Main St"))
        XCTAssertTrue(text.contains("ALLERGIES: penicillin"))
    }
}
