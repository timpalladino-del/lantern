import Foundation
import SwiftData

enum MedicationForm: String, CaseIterable, Codable, Identifiable {
    case tablet, capsule, liquid, injection, inhaler, patch, drops, cream, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .tablet: return "Tablet"
        case .capsule: return "Capsule"
        case .liquid: return "Liquid"
        case .injection: return "Injection"
        case .inhaler: return "Inhaler"
        case .patch: return "Patch"
        case .drops: return "Drops"
        case .cream: return "Cream or ointment"
        case .other: return "Other"
        }
    }
    /// What one "unit" is called when counting what is on hand.
    var unitName: String {
        switch self {
        case .tablet: return "tablets"
        case .capsule: return "capsules"
        case .liquid: return "doses"
        case .injection: return "doses"
        case .inhaler: return "puffs"
        case .patch: return "patches"
        case .drops: return "drops"
        case .cream: return "applications"
        case .other: return "units"
        }
    }
}

/// A medication one person takes. Days of supply is the readiness number that matters; the rest is
/// what a caregiver, a neighbour or an ER nurse needs to know when the person cannot say it themselves.
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

    // Added with the medication card. All optional so existing rows migrate untouched.
    var formRaw: String = MedicationForm.tablet.rawValue
    var purpose: String = ""                      // "blood pressure", "seizures"
    /// Minutes after midnight for each scheduled dose, e.g. [480, 1200] for 8:00 and 20:00.
    var scheduleMinutes: [Int] = []
    /// Keys from `MedicationInstruction` (take with food, no driving, ...).
    var instructionKeys: [String] = []
    var customInstructions: String = ""           // anything the catalog does not cover
    var prescriber: String = ""
    var prescriberPhone: String = ""
    var pharmacy: String = ""
    var pharmacyPhone: String = ""
    var rxNumber: String = ""
    var remindersEnabled: Bool = false

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

    var form: MedicationForm {
        get { MedicationForm(rawValue: formRaw) ?? .tablet }
        set { formRaw = newValue.rawValue }
    }

    var instructions: [MedicationInstruction] {
        instructionKeys.compactMap { MedicationInstruction(rawValue: $0) }
    }

    var unitsPerDay: Double { max(0, dosesPerDay * unitsPerDose) }

    var daysOfSupply: Double? {
        guard unitsPerDay > 0 else { return nil }
        return unitsOnHand / unitsPerDay
    }

    /// "8:00 AM, 8:00 PM" in the user's locale, or a count when no times are set.
    var scheduleSummary: String {
        if scheduleMinutes.isEmpty {
            if dosesPerDay == 0 { return "As needed" }
            if dosesPerDay == 1 { return "Once a day" }
            let n = dosesPerDay == dosesPerDay.rounded() ? String(Int(dosesPerDay)) : String(format: "%.1f", dosesPerDay)
            return "\(n) times a day"
        }
        return scheduleMinutes.sorted().map { Medication.timeString(minutes: $0) }.joined(separator: ", ")
    }

    static func timeString(minutes: Int) -> String {
        var comps = DateComponents()
        comps.hour = minutes / 60
        comps.minute = minutes % 60
        let date = Calendar.current.date(from: comps) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }

    /// One line a stranger could read out loud: "Metformin 500 mg, 1 tablet at 8:00 AM, 8:00 PM. Take with food."
    var cardLine: String {
        var s = name
        if !dose.isEmpty { s += " \(dose)" }
        let units = unitsPerDose == unitsPerDose.rounded() ? String(Int(unitsPerDose)) : String(format: "%.1f", unitsPerDose)
        let unitName = unitsPerDose == 1 ? String(form.unitName.dropLast()) : form.unitName
        s += ", \(units) \(unitName)"
        s += scheduleMinutes.isEmpty ? " \(scheduleSummary.lowercased())" : " at \(scheduleSummary)"
        s += "."
        let rules = instructions.map(\.title) + (customInstructions.isEmpty ? [] : [customInstructions])
        if !rules.isEmpty { s += " " + rules.joined(separator: ". ") + "." }
        return s
    }
}
