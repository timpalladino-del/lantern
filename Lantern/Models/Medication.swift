import Foundation
import SwiftData

/// A medication one person takes. Days of supply is the readiness number that matters.
@Model
final class Medication {
    var uuid: UUID = UUID()
    var name: String = ""
    var dose: String = ""           // "10 mg", "1 puff"
    var dosesPerDay: Double = 1
    var unitsPerDose: Double = 1    // tablets per dose
    var unitsOnHand: Double = 0
    var isCritical: Bool = false    // insulin, seizure meds, inhalers: the ones a bad week cannot interrupt
    var expirationDate: Date?
    var notes: String = ""
    var createdAt: Date = Date()

    var person: Person?

    init(name: String, dose: String = "", dosesPerDay: Double = 1, unitsPerDose: Double = 1, unitsOnHand: Double = 0, isCritical: Bool = false) {
        self.uuid = UUID()
        self.name = name
        self.dose = dose
        self.dosesPerDay = dosesPerDay
        self.unitsPerDose = unitsPerDose
        self.unitsOnHand = unitsOnHand
        self.isCritical = isCritical
        self.createdAt = Date()
    }

    var unitsPerDay: Double { max(0, dosesPerDay * unitsPerDose) }

    var daysOfSupply: Double? {
        guard unitsPerDay > 0 else { return nil }
        return unitsOnHand / unitsPerDay
    }
}
