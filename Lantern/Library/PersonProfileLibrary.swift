import Foundation

/// Vocabulary for the parts of a person's profile that matter in a bad week: what they can do, what
/// they need, and what runs on power. Plain lists, no scoring.
enum SkillGroup: String, CaseIterable, Identifiable {
    case medical = "Medical", practical = "Practical", outdoors = "Outdoors", communication = "Communication", care = "Care"
    var id: String { rawValue }
}

struct Skill: Identifiable, Hashable {
    let key: String
    let title: String
    let symbol: String
    let group: SkillGroup
    var id: String { key }
}

enum SkillLibrary {
    static let all: [Skill] = [
        Skill(key: "first_aid", title: "First aid", symbol: "cross.case", group: .medical),
        Skill(key: "cpr", title: "CPR / AED", symbol: "heart.circle", group: .medical),
        Skill(key: "nurse_doctor", title: "Nurse, doctor or EMT", symbol: "stethoscope", group: .medical),
        Skill(key: "stop_bleed", title: "Stop the Bleed trained", symbol: "bandage", group: .medical),
        Skill(key: "generator", title: "Runs the generator", symbol: "bolt.fill", group: .practical),
        Skill(key: "utilities", title: "Can shut off gas, water, power", symbol: "pipe.and.drop", group: .practical),
        Skill(key: "electrical", title: "Electrical", symbol: "powerplug", group: .practical),
        Skill(key: "plumbing", title: "Plumbing", symbol: "wrench", group: .practical),
        Skill(key: "carpentry", title: "Carpentry and repairs", symbol: "hammer", group: .practical),
        Skill(key: "mechanic", title: "Car and small-engine repair", symbol: "car", group: .practical),
        Skill(key: "chainsaw", title: "Chainsaw", symbol: "leaf", group: .practical),
        Skill(key: "cooking", title: "Cooks without power", symbol: "flame", group: .practical),
        Skill(key: "water_treatment", title: "Water purifying", symbol: "drop.triangle", group: .practical),
        Skill(key: "navigation", title: "Map and compass", symbol: "map", group: .outdoors),
        Skill(key: "fire", title: "Fire building", symbol: "flame.circle", group: .outdoors),
        Skill(key: "shelter", title: "Camping and shelter", symbol: "tent", group: .outdoors),
        Skill(key: "hunting_fishing", title: "Hunting or fishing", symbol: "fish", group: .outdoors),
        Skill(key: "gardening", title: "Gardening and food growing", symbol: "carrot", group: .outdoors),
        Skill(key: "foraging", title: "Foraging", symbol: "leaf.circle", group: .outdoors),
        Skill(key: "swimming", title: "Strong swimmer or lifeguard", symbol: "figure.pool.swim", group: .outdoors),
        Skill(key: "boating", title: "Boat handling", symbol: "sailboat", group: .outdoors),
        Skill(key: "ham_radio", title: "Ham or GMRS radio", symbol: "antenna.radiowaves.left.and.right", group: .communication),
        Skill(key: "languages", title: "Speaks another language", symbol: "globe", group: .communication),
        Skill(key: "sign_language", title: "Sign language", symbol: "hand.raised", group: .communication),
        Skill(key: "driving_large", title: "Drives a truck, trailer or RV", symbol: "truck.box", group: .communication),
        Skill(key: "childcare", title: "Childcare", symbol: "figure.and.child.holdinghands", group: .care),
        Skill(key: "elder_care", title: "Elder or disability care", symbol: "figure.roll", group: .care),
        Skill(key: "animal_care", title: "Animal handling", symbol: "pawprint", group: .care),
        Skill(key: "mental_health", title: "Counseling or calming people", symbol: "brain.head.profile", group: .care),
        Skill(key: "firearms", title: "Firearms safety", symbol: "shield", group: .care),
    ]

    static func skill(_ key: String) -> Skill? { all.first { $0.key == key } }

    static func titles(for keys: [String]) -> [String] { keys.compactMap { skill($0)?.title } }

    /// Skills nobody in the house has, from the short list that matters most. Used for one calm nudge.
    static let coreKeys = ["first_aid", "cpr", "utilities", "generator"]
}

/// Equipment someone depends on that stops when the power does. Drives the outage checklist.
struct PowerDevice: Identifiable, Hashable {
    let key: String
    let title: String
    let hint: String
    var id: String { key }

    static let all: [PowerDevice] = [
        PowerDevice(key: "cpap", title: "CPAP or BiPAP", hint: "A battery pack covers one or two nights. Ask the supplier about a DC cable."),
        PowerDevice(key: "oxygen", title: "Oxygen concentrator", hint: "Keep backup tanks. Register with the power company's medical baseline program."),
        PowerDevice(key: "nebulizer", title: "Nebulizer", hint: "A car inverter runs most units. Keep a rescue inhaler as backup."),
        PowerDevice(key: "insulin", title: "Insulin or refrigerated medicine", hint: "A small cooler with ice packs holds 48 hours. Unopened insulin keeps a month at room temperature."),
        PowerDevice(key: "power_wheelchair", title: "Power wheelchair or scooter", hint: "Keep a manual backup if possible. Charge fully before a storm."),
        PowerDevice(key: "dialysis", title: "Home dialysis", hint: "Your clinic has a storm plan. Know the nearest in-center unit."),
        PowerDevice(key: "feeding_pump", title: "Feeding or infusion pump", hint: "Ask the supplier for a battery or gravity backup."),
        PowerDevice(key: "hearing", title: "Hearing aids or cochlear implant", hint: "Stock batteries or a charger that runs from a power bank."),
        PowerDevice(key: "lift", title: "Patient lift or hospital bed", hint: "Know the manual release. Keep a flashlight by the bed."),
        PowerDevice(key: "phone", title: "Depends on phone for contact", hint: "A charged power bank and a written list of numbers."),
    ]

    static func device(_ key: String) -> PowerDevice? { all.first { $0.key == key } }
}

enum Mobility: String, CaseIterable, Codable, Identifiable {
    case independent, someHelp, wheelchair, bedbound
    var id: String { rawValue }
    var title: String {
        switch self {
        case .independent: return "Gets around on their own"
        case .someHelp: return "Needs some help"
        case .wheelchair: return "Uses a wheelchair or walker"
        case .bedbound: return "Mostly in bed"
        }
    }
    var needsHelpToLeave: Bool { self != .independent }
}

enum BloodType: String, CaseIterable, Codable, Identifiable {
    case unknown = "", oPos = "O+", oNeg = "O-", aPos = "A+", aNeg = "A-", bPos = "B+", bNeg = "B-", abPos = "AB+", abNeg = "AB-"
    var id: String { rawValue }
    var title: String { rawValue.isEmpty ? "Not sure" : rawValue }
}

/// Anything the person wants remembered that the app did not think to ask. "Add a field."
struct CustomField: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var label: String
    var value: String
}

extension CustomField {
    static func encode(_ fields: [CustomField]) -> String {
        guard let data = try? JSONEncoder().encode(fields) else { return "" }
        return String(decoding: data, as: UTF8.self)
    }
    static func decode(_ json: String) -> [CustomField] {
        guard !json.isEmpty, let data = json.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([CustomField].self, from: data)) ?? []
    }
}
