import Foundation

/// What the form asks for each kind of equipment. A go-bag has no batteries; an extinguisher has a class
/// and a manufacture date; a generator has fuel and watts. Answers to the kind questions live in
/// `Equipment.details` keyed by `EquipmentQuestion.key`.
enum EquipmentField: String, CaseIterable {
    case brand, model, serial, batteries, purchaseDate, manufactureDate
}

struct EquipmentQuestion: Identifiable, Hashable {
    enum Kind: Hashable { case text, number, toggle, choice([String]) }
    let key: String
    let label: String
    let placeholder: String
    let kind: Kind
    var id: String { key }

    static func text(_ key: String, _ label: String, _ placeholder: String = "") -> EquipmentQuestion { .init(key: key, label: label, placeholder: placeholder, kind: .text) }
    static func number(_ key: String, _ label: String, _ placeholder: String = "") -> EquipmentQuestion { .init(key: key, label: label, placeholder: placeholder, kind: .number) }
    static func toggle(_ key: String, _ label: String) -> EquipmentQuestion { .init(key: key, label: label, placeholder: "", kind: .toggle) }
    static func choice(_ key: String, _ label: String, _ options: [String]) -> EquipmentQuestion { .init(key: key, label: label, placeholder: "", kind: .choice(options)) }
}

struct EquipmentProfile {
    let fields: Set<EquipmentField>
    let questions: [EquipmentQuestion]
    let namePlaceholder: String
    let notesPlaceholder: String
    /// Shown above the questions, for kinds that are really containers tracked elsewhere.
    let hint: String?

    static let all: Set<EquipmentField> = Set(EquipmentField.allCases)
    static let ids: Set<EquipmentField> = [.brand, .model, .serial]

    static func profile(for kind: String) -> EquipmentProfile {
        profiles[kind] ?? EquipmentProfile(fields: all, questions: [], namePlaceholder: "Name", notesPlaceholder: "Anything worth knowing in a bad week", hint: nil)
    }

    static let profiles: [String: EquipmentProfile] = [
        "generator": .init(fields: ids.union([.purchaseDate]), questions: [
            .choice("fuel", "Fuel", ["Gasoline", "Propane", "Dual fuel", "Diesel"]),
            .number("runningWatts", "Running watts", "2200"),
            .text("oil", "Oil type", "10W-30"),
            .number("hours", "Hours on the meter", "0"),
            .choice("start", "Starts by", ["Pull cord", "Electric start", "Both"]),
            .toggle("transferSwitch", "Transfer switch installed"),
        ], namePlaceholder: "Garage generator", notesPlaceholder: "Where the key and the cords are, what it can run at once", hint: nil),
        "powerStation": .init(fields: ids.union([.purchaseDate]), questions: [
            .number("capacityWh", "Capacity (Wh)", "1000"),
            .number("chargeNow", "Charge now (%)", "80"),
            .choice("recharge", "Recharges from", ["Wall", "Car", "Solar panel", "All three"]),
            .number("solarWatts", "Solar panel watts", "100"),
        ], namePlaceholder: "Power station", notesPlaceholder: "What it runs and for how long", hint: nil),
        "fireExtinguisher": .init(fields: ids.union([.manufactureDate]), questions: [
            .choice("class", "Class", ["ABC", "BC", "K (kitchen)", "A (water)"]),
            .choice("size", "Size", ["2.5 lb", "5 lb", "10 lb", "20 lb"]),
            .toggle("rechargeable", "Rechargeable"),
            .text("inspection", "Last inspection tag", "Mar 2026"),
        ], namePlaceholder: "Kitchen extinguisher", notesPlaceholder: "Mounted where", hint: nil),
        "smokeAlarm": .init(fields: [.brand, .model, .batteries, .manufactureDate], questions: [
            .number("count", "How many in the house", "4"),
            .choice("power", "Power", ["Battery only", "Hardwired with battery backup", "10-year sealed battery"]),
            .toggle("interconnected", "Interconnected"),
            .toggle("combo", "Combination smoke and CO"),
        ], namePlaceholder: "Smoke alarms", notesPlaceholder: "Which rooms", hint: nil),
        "coAlarm": .init(fields: [.brand, .model, .batteries, .manufactureDate], questions: [
            .number("count", "How many in the house", "2"),
            .choice("power", "Power", ["Battery only", "Plug-in with battery backup", "Hardwired"]),
            .toggle("digitalReadout", "Digital ppm readout"),
        ], namePlaceholder: "CO alarms", notesPlaceholder: "Which rooms, near which appliances", hint: nil),
        "firstAidKit": .init(fields: [.purchaseDate], questions: [
            .choice("size", "Kit size", ["Pocket", "Family", "Trauma / large"]),
            .toggle("tourniquet", "Tourniquet included"),
            .toggle("rxInside", "Prescription meds inside"),
            .text("for", "Who it's for", "Whole house"),
        ], namePlaceholder: "Hall closet first aid kit", notesPlaceholder: "What's missing or custom", hint: nil),
        "goBag": .init(fields: [.purchaseDate], questions: [
            .text("packedFor", "Packed for", "Tim and Maria"),
            .choice("season", "Season last swapped", ["Winter", "Summer", "Not yet"]),
        ], namePlaceholder: "Hall closet go-bag", notesPlaceholder: "Where it lives", hint: "Track what's inside under Supplies → Kits. This record is for the bag itself and its checks."),
        "vehicleKit": .init(fields: [.purchaseDate], questions: [
            .text("vehicle", "Vehicle", "Blue Honda"),
            .choice("season", "Season last swapped", ["Winter", "Summer", "Not yet"]),
        ], namePlaceholder: "Car kit", notesPlaceholder: "Trunk or under the seat", hint: "Track what's inside under Supplies → Kits. This record is for the kit itself and its checks."),
        "waterFilter": .init(fields: [.brand, .model, .purchaseDate], questions: [
            .choice("type", "Filter type", ["Pitcher", "Faucet", "Under-sink", "Whole-house", "Gravity (countertop)", "Portable / straw"]),
            .text("element", "Replacement element part", "BB9-2"),
            .number("capacityGal", "Element capacity (gallons)", "3000"),
            .text("lastChange", "Last element change", "Aug 2026"),
        ], namePlaceholder: "Kitchen water filter", notesPlaceholder: "Where spare elements are", hint: nil),
        "propaneCylinder": .init(fields: [.manufactureDate], questions: [
            .choice("size", "Size", ["1 lb", "20 lb", "30 lb", "40 lb", "100 lb"]),
            .number("count", "How many", "2"),
            .choice("level", "How full", ["Full", "Half", "Low", "Empty"]),
            .text("usedFor", "Used for", "Grill, heater"),
        ], namePlaceholder: "Propane cylinders", notesPlaceholder: "Stored where (outdoors, upright)", hint: "The manufacture date is the requalification clock: 12 years, stamped on the collar."),
        "fuelCan": .init(fields: [], questions: [
            .choice("fuel", "Fuel", ["Gasoline", "Diesel", "Kerosene", "Mixed 2-stroke"]),
            .number("count", "How many cans", "2"),
            .number("capacityGal", "Capacity each (gal)", "5"),
            .toggle("stabilizer", "Stabilizer added"),
            .text("lastFilled", "Last filled", "Oct 2026"),
        ], namePlaceholder: "Gas cans", notesPlaceholder: "Rotate into the car every few months", hint: nil),
        "sumpPump": .init(fields: ids.union([.purchaseDate, .manufactureDate]), questions: [
            .toggle("backup", "Battery backup"),
            .text("backupBattery", "Backup battery type", "Deep-cycle 12V"),
            .text("hp", "Horsepower", "1/3"),
            .toggle("alarm", "Water alarm installed"),
        ], namePlaceholder: "Basement sump pump", notesPlaceholder: "Where the discharge goes", hint: nil),
        "flashlight": .init(fields: [.brand, .model, .batteries, .purchaseDate], questions: [
            .number("count", "How many", "3"),
            .toggle("rechargeable", "Rechargeable (USB)"),
            .number("lumens", "Lumens", "300"),
        ], namePlaceholder: "Flashlights", notesPlaceholder: "Which drawer", hint: nil),
        "radio": .init(fields: [.brand, .model, .batteries, .purchaseDate], questions: [
            .toggle("noaa", "NOAA weather band"),
            .toggle("crank", "Hand crank"),
            .toggle("solar", "Solar"),
            .toggle("chargesPhone", "Charges a phone"),
        ], namePlaceholder: "Emergency radio", notesPlaceholder: "Local station: 162.550 MHz", hint: nil),
        "chainsaw": .init(fields: ids.union([.purchaseDate]), questions: [
            .choice("power", "Power", ["Gas", "Battery", "Electric cord"]),
            .number("bar", "Bar length (in)", "16"),
            .text("chain", "Chain size", "3/8 LP, .050, 56 links"),
            .text("mix", "Fuel mix", "50:1"),
        ], namePlaceholder: "Chainsaw", notesPlaceholder: "Bar oil, spare chain, PPE", hint: nil),
        "heater": .init(fields: ids.union([.purchaseDate]), questions: [
            .choice("fuel", "Fuel", ["Propane", "Kerosene", "Electric"]),
            .toggle("indoorRated", "Indoor rated (oxygen sensor and tip-over shutoff)"),
            .number("btu", "BTU", "9000"),
            .text("runtime", "Runs how long on a tank", "6 hours on 1 lb"),
        ], namePlaceholder: "Indoor heater", notesPlaceholder: "Never without a CO alarm in the room", hint: nil),
    ]
}
