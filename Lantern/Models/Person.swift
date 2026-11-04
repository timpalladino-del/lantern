import Foundation
import SwiftData

enum Sex: String, CaseIterable, Codable, Identifiable {
    case unspecified, female, male
    var id: String { rawValue }
    var title: String {
        switch self {
        case .unspecified: return "Prefer not to say"
        case .female: return "Female"
        case .male: return "Male"
        }
    }
}

enum ActivityLevel: String, CaseIterable, Codable, Identifiable {
    case sedentary, light, active
    var id: String { rawValue }
    var title: String {
        switch self {
        case .sedentary: return "Mostly sitting"
        case .light: return "On my feet some"
        case .active: return "Active most days"
        }
    }
    /// Multiplier on resting energy, Dietary Guidelines style.
    var factor: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .active: return 1.55
        }
    }
}

/// One member of the household. Everything optional except a name; the calculator fills gaps with
/// Dietary Guidelines averages and says so.
@Model
final class Person {
    var uuid: UUID = UUID()
    var name: String = ""
    var age: Int?
    var weightKg: Double?
    var heightCm: Double?
    var sexRaw: String = Sex.unspecified.rawValue
    var activityRaw: String = ActivityLevel.light.rawValue
    var allergies: String = ""
    var dietaryNotes: String = ""
    var notes: String = ""
    var sortOrder: Int = 0
    var createdAt: Date = Date()

    // Contact
    var phone: String = ""
    var emergencyContactName: String = ""
    var emergencyContactPhone: String = ""

    // Health beyond medications
    var bloodTypeRaw: String = ""
    var conditions: String = ""
    var mobilityRaw: String = Mobility.independent.rawValue
    /// Keys from `PowerDevice.all`. Anything here goes on the outage checklist.
    var powerDeviceKeys: [String] = []

    // Wellness: what keeps this person steady when routine breaks.
    var wellnessNotes: String = ""
    var comfortNeeds: String = ""

    // What they bring
    /// Keys from `SkillLibrary.all`.
    var skillKeys: [String] = []
    var languages: String = ""
    var canDrive: Bool = false
    /// Their job when something happens: "grabs the dog", "shuts off the gas", "calls Aunt Pat".
    var emergencyRole: String = ""

    /// Anything else, as label/value pairs. JSON so the schema never needs another column for it.
    var customFieldsJSON: String = ""

    @Relationship(deleteRule: .cascade, inverse: \Medication.person)
    var medications: [Medication] = []

    var household: Household?

    init(name: String, age: Int? = nil, weightKg: Double? = nil, heightCm: Double? = nil, sex: Sex = .unspecified, activity: ActivityLevel = .light) {
        self.uuid = UUID()
        self.name = name
        self.age = age
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.sexRaw = sex.rawValue
        self.activityRaw = activity.rawValue
        self.createdAt = Date()
    }

    var sex: Sex {
        get { Sex(rawValue: sexRaw) ?? .unspecified }
        set { sexRaw = newValue.rawValue }
    }

    var activity: ActivityLevel {
        get { ActivityLevel(rawValue: activityRaw) ?? .light }
        set { activityRaw = newValue.rawValue }
    }

    var bloodType: BloodType {
        get { BloodType(rawValue: bloodTypeRaw) ?? .unknown }
        set { bloodTypeRaw = newValue.rawValue }
    }

    var mobility: Mobility {
        get { Mobility(rawValue: mobilityRaw) ?? .independent }
        set { mobilityRaw = newValue.rawValue }
    }

    var customFields: [CustomField] {
        get { CustomField.decode(customFieldsJSON) }
        set { customFieldsJSON = CustomField.encode(newValue) }
    }

    var skills: [Skill] { skillKeys.compactMap { SkillLibrary.skill($0) } }
    var powerDevices: [PowerDevice] { powerDeviceKeys.compactMap { PowerDevice.device($0) } }
    var dependsOnPower: Bool { !powerDeviceKeys.isEmpty }

    /// Two letters for the avatar circle.
    var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first }.map { String($0).uppercased() }
        return letters.isEmpty ? "?" : letters.joined()
    }

    /// True when the profile has nothing beyond a name. The home screen nudges for details.
    var profileIsBare: Bool { age == nil && medications.isEmpty && skillKeys.isEmpty && conditions.isEmpty && phone.isEmpty }

    var isInfant: Bool { (age ?? 30) < 1 }
    var isChild: Bool { (age ?? 30) < 18 }

    /// Calories per day. Mifflin-St Jeor when weight and height are known; otherwise Dietary Guidelines age bands.
    var dailyCalories: Double { CalorieEstimator.dailyCalories(for: self) }

    /// True when the estimate came from averages rather than this person's numbers.
    var caloriesAreEstimated: Bool { weightKg == nil || heightCm == nil || age == nil }
}

/// Calorie math, kept pure so it can be tested.
enum CalorieEstimator {
    static func dailyCalories(for p: Person) -> Double {
        dailyCalories(age: p.age, weightKg: p.weightKg, heightCm: p.heightCm, sex: p.sex, activity: p.activity)
    }

    static func dailyCalories(age: Int?, weightKg: Double?, heightCm: Double?, sex: Sex, activity: ActivityLevel) -> Double {
        if let age, age < 1 { return 0 }  // infants: formula or breast milk, tracked as supplies not calories
        if let w = weightKg, let h = heightCm, let a = age, a >= 3 {
            // Mifflin-St Jeor resting energy, then activity.
            let base = 10 * w + 6.25 * h - 5 * Double(a)
            let rmr: Double
            switch sex {
            case .male: rmr = base + 5
            case .female: rmr = base - 161
            case .unspecified: rmr = base - 78
            }
            return max(900, rmr * activity.factor)
        }
        return guidelineCalories(age: age, sex: sex, activity: activity)
    }

    /// USDA Dietary Guidelines 2020-2025 estimated needs, collapsed to a sensible midpoint per band.
    static func guidelineCalories(age: Int?, sex: Sex, activity: ActivityLevel) -> Double {
        let a = age ?? 35
        let female: Double
        let male: Double
        switch a {
        case ..<1: return 0
        case 1...3: female = 1100; male = 1200
        case 4...8: female = 1400; male = 1500
        case 9...13: female = 1700; male = 1900
        case 14...18: female = 1900; male = 2500
        case 19...30: female = 2000; male = 2600
        case 31...50: female = 1900; male = 2400
        default: female = 1700; male = 2200
        }
        let bySex: Double
        switch sex {
        case .female: bySex = female
        case .male: bySex = male
        case .unspecified: bySex = (female + male) / 2
        }
        // The guideline bands already assume moderate activity; nudge for the extremes.
        switch activity {
        case .sedentary: return bySex * 0.9
        case .light: return bySex
        case .active: return bySex * 1.12
        }
    }
}
