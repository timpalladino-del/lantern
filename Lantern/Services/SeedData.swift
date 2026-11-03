import Foundation
import SwiftData

/// First-launch defaults: locations and a household row. Nothing else; the user's data is theirs.
enum SeedData {
    @MainActor
    static func ensureDefaults(in context: ModelContext) {
        let locations = (try? context.fetch(FetchDescriptor<StorageLocation>())) ?? []
        if locations.isEmpty {
            for (index, pair) in StorageLocation.defaults.enumerated() {
                context.insert(StorageLocation(name: pair.0, symbol: pair.1, sortOrder: index))
            }
        }
        let households = (try? context.fetch(FetchDescriptor<Household>())) ?? []
        if households.isEmpty {
            context.insert(Household())
        }
        let contacts = (try? context.fetch(FetchDescriptor<EmergencyContact>())) ?? []
        if contacts.isEmpty {
            for (i, c) in EmergencyContact.defaults.enumerated() {
                context.insert(EmergencyContact(name: c.0, role: c.1, phone: c.2, notes: c.3, isBuiltIn: true, sortOrder: i))
            }
        }
        let plans = (try? context.fetch(FetchDescriptor<HouseholdPlan>())) ?? []
        if plans.isEmpty {
            context.insert(HouseholdPlan())
        }
        try? context.save()
    }

    /// Adds a starter pack's lines to a location, estimating dates from today.
    @MainActor
    static func apply(pack: StarterPack, to location: StorageLocation?, in context: ModelContext, library: ShelfLifeLibrary = .shared) {
        for line in pack.items {
            context.insert(makeItem(from: line, location: location, kit: nil, library: library))
        }
        try? context.save()
    }

    /// One template line as a real item, dated today with an estimated best-by when the library knows one.
    @discardableResult
    static func makeItem(from line: StarterPackItem, location: StorageLocation?, kit: Kit?, library: ShelfLifeLibrary = .shared) -> SupplyItem {
        let today = Date()
        let item = SupplyItem(name: line.name, category: SupplyCategory.from(line.category), quantity: line.quantity, unit: line.unit, location: location)
        item.purchaseDate = today
        item.servingsPerUnit = line.servingsPerUnit
        item.litersPerUnit = line.litersPerUnit
        item.kit = kit
        if let key = line.shelfLifeKey, let entry = library.entry(for: key) {
            item.shelfLifeKey = key
            if !entry.needsPrintedDate, let est = entry.estimate(from: today, opened: false, deepStorage: false) {
                item.expirationDate = est
                item.dateSource = .estimated
            }
        }
        return item
    }
}

// MARK: - Demo data for screenshots

extension SeedData {
    /// A believable household for App Store screenshots. Debug builds only, launch argument `-demo`.
    /// Idempotent: does nothing if a person named "Maria" already exists.
    @MainActor
    static func demo(in context: ModelContext) {
        ensureDefaults(in: context)
        let existing = (try? context.fetch(FetchDescriptor<Person>()))?.contains { $0.name == "Maria" } ?? false
        guard !existing else { return }
        let now = Date()
        func days(_ n: Int) -> Date { Calendar.current.date(byAdding: .day, value: n, to: now)! }

        let household = (try? context.fetch(FetchDescriptor<Household>()))?.first ?? {
            let h = Household(); context.insert(h); return h
        }()
        household.targetDays = 14

        let tim = Person(name: "Tim", age: 44, weightKg: 86, heightCm: 180, sex: .male, activity: .light)
        let maria = Person(name: "Maria", age: 42, weightKg: 68, heightCm: 165, sex: .female, activity: .light)
        maria.allergies = "Penicillin"
        let leo = Person(name: "Leo", age: 9, sex: .male, activity: .active)
        for (i, p) in [tim, maria, leo].enumerated() { p.sortOrder = i; p.household = household; context.insert(p) }

        let metformin = Medication(name: "Metformin", dose: "500 mg", dosesPerDay: 2, unitsPerDose: 1, unitsOnHand: 48)
        metformin.purpose = "Type 2 diabetes"
        metformin.scheduleMinutes = [8 * 60, 20 * 60]
        metformin.instructionKeys = ["withFood", "noAlcohol", "lowSugar"]
        metformin.prescriber = "Dr. Alvarez"; metformin.prescriberPhone = "(305) 555-0142"
        metformin.pharmacy = "CVS, Main St"; metformin.pharmacyPhone = "(305) 555-0199"; metformin.rxNumber = "7731904"
        metformin.remindersEnabled = true
        metformin.person = maria; context.insert(metformin)
        let lisinopril = Medication(name: "Lisinopril", dose: "10 mg", dosesPerDay: 1, unitsPerDose: 1, unitsOnHand: 9, isCritical: true)
        lisinopril.purpose = "Blood pressure"; lisinopril.scheduleMinutes = [8 * 60]
        lisinopril.instructionKeys = ["sameTimeDaily", "noNSAIDs"]; lisinopril.prescriber = "Dr. Alvarez"; lisinopril.pharmacy = "CVS, Main St"
        lisinopril.person = tim; context.insert(lisinopril)
        let inhaler = Medication(name: "Albuterol inhaler", dose: "90 mcg", dosesPerDay: 0, unitsPerDose: 2, unitsOnHand: 200, isCritical: true)
        inhaler.formRaw = MedicationForm.inhaler.rawValue; inhaler.purpose = "Asthma"; inhaler.instructionKeys = ["shakeWell"]
        inhaler.person = leo; context.insert(inhaler)

        let biscuit = Pet(name: "Biscuit", species: .dog, weightKg: 24)
        biscuit.household = household; context.insert(biscuit)

        let plan = (try? context.fetch(FetchDescriptor<HouseholdPlan>()))?.first ?? { let p = HouseholdPlan(); context.insert(p); return p }()
        plan.meetNearHome = "The mailbox at the end of the driveway"
        plan.meetOutsideNeighborhood = "Library parking lot on Main"
        plan.outOfTownContact = "Aunt Pat in Ohio, (614) 555-0133"
        plan.petsPlan = "Carrier in the hall closet. Leo grabs Biscuit."
        plan.documentsLocation = "Fireproof box, bedroom closet"
        plan.trustedContactName = "Dana, next door"; plan.trustedContactPhone = "(305) 555-0177"
        plan.noaaStation = "162.550 MHz"
        plan.lastReviewedAt = days(-20)

        let locations = (try? context.fetch(FetchDescriptor<StorageLocation>(sortBy: [SortDescriptor(\.sortOrder)]))) ?? []
        let pantry = locations.first, garage = locations.dropFirst().first
        let library = ShelfLifeLibrary.shared
        struct L { let n: String; let c: String; let q: Double; let u: String; let key: String?; let exp: Int?; let kcal: Double?; let l: Double?; let loc: Int }
        let lines: [L] = [
            L(n: "Bottled water", c: "water", q: 6, u: "gal", key: "water_bottled", exp: 300, kcal: nil, l: 3.785, loc: 1),
            L(n: "Water bricks (filled)", c: "water", q: 4, u: "each", key: "water_filled", exp: 120, kcal: nil, l: 13.2, loc: 1),
            L(n: "Black beans", c: "food", q: 12, u: "can", key: "canned_low_acid", exp: 540, kcal: 350, l: nil, loc: 0),
            L(n: "Chicken noodle soup", c: "food", q: 8, u: "can", key: "canned_low_acid", exp: 9, kcal: 220, l: nil, loc: 0),
            L(n: "Peanut butter", c: "food", q: 2, u: "jar", key: "peanut_butter", exp: 200, kcal: 2700, l: nil, loc: 0),
            L(n: "White rice", c: "food", q: 10, u: "lb", key: "rice_white", exp: 1200, kcal: 1650, l: nil, loc: 0),
            L(n: "Rolled oats", c: "food", q: 4, u: "lb", key: "oats", exp: 300, kcal: 1700, l: nil, loc: 0),
            L(n: "Canned tuna", c: "food", q: 10, u: "can", key: "canned_fish", exp: 700, kcal: 190, l: nil, loc: 0),
            L(n: "Granola bars", c: "food", q: 24, u: "bar", key: "bars", exp: 4, kcal: 190, l: nil, loc: 0),
            L(n: "Crackers", c: "food", q: 3, u: "box", key: "crackers", exp: 60, kcal: 1300, l: nil, loc: 0),
            L(n: "Pasta", c: "food", q: 6, u: "lb", key: "pasta_dry", exp: 600, kcal: 1700, l: nil, loc: 0),
            L(n: "Pasta sauce", c: "food", q: 6, u: "jar", key: "canned_high_acid", exp: 400, kcal: 400, l: nil, loc: 0),
            L(n: "Dog food", c: "pet", q: 1, u: "bag", key: "pet_food_dry", exp: 90, kcal: nil, l: nil, loc: 1),
            L(n: "AA batteries", c: "power", q: 24, u: "each", key: "batteries_alkaline", exp: 2500, kcal: nil, l: nil, loc: 1),
            L(n: "D batteries", c: "power", q: 8, u: "each", key: "batteries_alkaline", exp: 2000, kcal: nil, l: nil, loc: 1),
            L(n: "LED lantern", c: "power", q: 2, u: "each", key: nil, exp: nil, kcal: nil, l: nil, loc: 1),
            L(n: "Flashlight", c: "power", q: 3, u: "each", key: nil, exp: nil, kcal: nil, l: nil, loc: 1),
            L(n: "Battery bank", c: "power", q: 1, u: "each", key: nil, exp: nil, kcal: nil, l: nil, loc: 0),
            L(n: "First aid kit", c: "medicine", q: 1, u: "kit", key: "first_aid_kit", exp: 180, kcal: nil, l: nil, loc: 0),
            L(n: "Children's ibuprofen", c: "medicine", q: 1, u: "bottle", key: nil, exp: -12, kcal: nil, l: nil, loc: 0),
            L(n: "Hand sanitizer", c: "hygiene", q: 2, u: "bottle", key: "hand_sanitizer", exp: 400, kcal: nil, l: nil, loc: 0),
            L(n: "Toilet paper", c: "hygiene", q: 24, u: "roll", key: nil, exp: nil, kcal: nil, l: nil, loc: 1),
            L(n: "Propane (20 lb)", c: "tools", q: 2, u: "each", key: nil, exp: nil, kcal: nil, l: nil, loc: 1),
            L(n: "Duct tape", c: "tools", q: 2, u: "roll", key: nil, exp: nil, kcal: nil, l: nil, loc: 1),
            L(n: "Tarp", c: "tools", q: 1, u: "each", key: nil, exp: nil, kcal: nil, l: nil, loc: 1),
        ]
        var created: [String: SupplyItem] = [:]
        for l in lines {
            let item = SupplyItem(name: l.n, category: SupplyCategory.from(l.c), quantity: l.q, unit: l.u, location: l.loc == 0 ? pantry : garage)
            item.purchaseDate = days(-30)
            item.shelfLifeKey = l.key
            item.caloriesPerUnit = l.kcal
            item.litersPerUnit = l.l
            if let e = l.exp { item.expirationDate = days(e); item.dateSource = l.key == nil ? .manual : .estimated }
            if l.n == "Water bricks (filled)" { item.fillDate = days(-60) }
            _ = library
            context.insert(item)
            created[l.n] = item
        }

        let generator = Equipment(name: "Honda EU2200i generator", kind: "generator", location: garage)
        generator.fuelType = "Gasoline"
        context.insert(generator)
        let run = MaintenanceTask(title: "Exercise run, 15 to 20 minutes under light load", intervalDays: 30, source: "Honda owner's manual", anchorDate: days(-33))
        run.equipment = generator; context.insert(run)
        let oil = MaintenanceTask(title: "Oil change", intervalDays: 180, source: "Honda owner's manual", anchorDate: days(-100))
        oil.equipment = generator; context.insert(oil)
        let smoke = Equipment(name: "Smoke alarms (4)", kind: "smokeAlarm", location: pantry)
        context.insert(smoke)
        let press = MaintenanceTask(title: "Press the test button", intervalDays: 30, source: "NFPA", anchorDate: days(-28))
        press.equipment = smoke; context.insert(press)
        let ext = Equipment(name: "Kitchen fire extinguisher", kind: "fireExtinguisher", location: pantry)
        context.insert(ext)
        let gauge = MaintenanceTask(title: "Visual check: gauge in the green, pin in place", intervalDays: 30, source: "NFPA 10", anchorDate: days(-5))
        gauge.equipment = ext; context.insert(gauge)

        let kit = Kit(name: "Hall closet go-bag", kind: .goBag, templateKey: "go_bag")
        kit.notes = pantry?.name ?? ""
        kit.lastCheckedAt = days(-40)
        context.insert(kit)
        if let t = KitLibrary.shared.template("go_bag") {
            for line in t.items.prefix(14) { context.insert(makeItem(from: line, location: pantry, kit: kit)) }
        }

        let outage = OutageEvent(startedAt: Calendar.current.date(byAdding: .minute, value: -95, to: now)!)
        outage.freezerIsFull = true
        context.insert(outage)

        let contacts = (try? context.fetch(FetchDescriptor<EmergencyContact>())) ?? []
        if !contacts.contains(where: { $0.name.hasPrefix("Dr.") }) {
            let doc = EmergencyContact(name: "Dr. Alvarez", role: "Family doctor", phone: "(305) 555-0142")
            doc.sortOrder = 10
            context.insert(doc)
        }
        try? context.save()
    }
}
