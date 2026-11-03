import SwiftUI
import SwiftData

/// Add or edit one person. Weight and height are optional and in US units on screen.
struct PersonEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let household: Household
    private let existing: Person?

    @State private var name: String
    @State private var hasAge: Bool
    @State private var age: Int
    @State private var sex: Sex
    @State private var activity: ActivityLevel
    @State private var weightLb: Double?
    @State private var heightFt: Int
    @State private var heightIn: Int
    @State private var hasHeight: Bool
    @State private var allergies: String
    @State private var dietaryNotes: String
    @State private var notes: String
    @State private var editingMedication: Medication?
    @State private var showNewMedication = false

    init(household: Household, person: Person? = nil) {
        self.household = household
        self.existing = person
        _name = State(initialValue: person?.name ?? "")
        _hasAge = State(initialValue: person?.age != nil)
        _age = State(initialValue: person?.age ?? 35)
        _sex = State(initialValue: person?.sex ?? .unspecified)
        _activity = State(initialValue: person?.activity ?? .light)
        _weightLb = State(initialValue: person?.weightKg.map { ($0 * 2.20462).rounded() })
        let totalIn = person?.heightCm.map { Int(($0 / 2.54).rounded()) }
        _hasHeight = State(initialValue: totalIn != nil)
        _heightFt = State(initialValue: (totalIn ?? 66) / 12)
        _heightIn = State(initialValue: (totalIn ?? 66) % 12)
        _allergies = State(initialValue: person?.allergies ?? "")
        _dietaryNotes = State(initialValue: person?.dietaryNotes ?? "")
        _notes = State(initialValue: person?.notes ?? "")
    }

    private var previewCalories: Double {
        let kg = weightLb.map { $0 / 2.20462 }
        let cm: Double? = hasHeight ? Double(heightFt * 12 + heightIn) * 2.54 : nil
        return CalorieEstimator.dailyCalories(age: hasAge ? age : nil, weightKg: kg, heightCm: cm, sex: sex, activity: activity)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    Toggle("Age", isOn: $hasAge)
                    if hasAge {
                        Stepper("\(age) years old", value: $age, in: 0...110)
                    }
                    Picker("Sex", selection: $sex) {
                        ForEach(Sex.allCases) { Text($0.title).tag($0) }
                    }
                    Picker("Activity", selection: $activity) {
                        ForEach(ActivityLevel.allCases) { Text($0.title).tag($0) }
                    }
                } footer: {
                    Text("Age and sex set the calorie estimate. Weight and height make it personal; leave them blank and the app uses national averages.")
                }

                Section("Size (optional)") {
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("lb", value: $weightLb, format: .number)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 90)
                        Text("lb").foregroundStyle(.secondary)
                    }
                    Toggle("Height", isOn: $hasHeight)
                    if hasHeight {
                        HStack {
                            Picker("ft", selection: $heightFt) { ForEach(1...7, id: \.self) { Text("\($0) ft").tag($0) } }
                            Picker("in", selection: $heightIn) { ForEach(0...11, id: \.self) { Text("\($0) in").tag($0) } }
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section {
                    if hasAge && age < 1 {
                        Label("Under one: counted as formula or stored milk, not calories.", systemImage: "info.circle")
                            .font(.subheadline)
                    } else {
                        LabeledContent("Needs about", value: "\(Int(previewCalories.rounded())) calories a day")
                    }
                } header: { Text("Food") } footer: {
                    Text("Mifflin-St Jeor when weight and height are known, otherwise USDA Dietary Guidelines bands. A planning number, not medical advice.")
                }

                Section("Medications") {
                    if let p = existing {
                        ForEach(p.medications.sorted { $0.createdAt < $1.createdAt }, id: \.uuid) { m in
                            Button { editingMedication = m } label: { MedicationRow(medication: m) }
                                .foregroundStyle(.primary)
                                .swipeActions {
                                    Button(role: .destructive) { context.delete(m); try? context.save() } label: { Label("Delete", systemImage: "trash") }
                                }
                        }
                        Button { showNewMedication = true } label: { Label("Add a medication", systemImage: "plus") }
                    } else {
                        Text("Save this person first, then add medications.").foregroundStyle(.secondary)
                    }
                }

                Section("Health notes") {
                    TextField("Allergies (peanuts, penicillin, bee stings…)", text: $allergies, axis: .vertical)
                    TextField("Diet (vegetarian, gluten-free, diabetic…)", text: $dietaryNotes, axis: .vertical)
                    TextField("Anything else worth knowing in a bad week", text: $notes, axis: .vertical).lineLimit(2...5)
                }
            }
            .navigationTitle(existing == nil ? "Add a person" : name.isEmpty ? "Person" : name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(item: $editingMedication) { m in
                MedicationEditView(person: existing!, medication: m)
            }
            .sheet(isPresented: $showNewMedication) {
                if let p = existing { MedicationEditView(person: p) }
            }
        }
    }

    private func save() {
        let p = existing ?? Person(name: name)
        p.name = name.trimmingCharacters(in: .whitespaces)
        p.age = hasAge ? age : nil
        p.sex = sex
        p.activity = activity
        p.weightKg = weightLb.map { $0 / 2.20462 }
        p.heightCm = hasHeight ? Double(heightFt * 12 + heightIn) * 2.54 : nil
        p.allergies = allergies
        p.dietaryNotes = dietaryNotes
        p.notes = notes
        if existing == nil {
            p.sortOrder = household.people.count
            p.household = household
            context.insert(p)
        }
        try? context.save()
        dismiss()
    }
}

struct MedicationRow: View {
    let medication: Medication
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(medication.name)
                    if medication.isCritical { Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.orange).font(.caption) }
                }
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if let d = medication.daysOfSupply {
                Text(ReadinessCalculator.formatDays(d))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(d < 7 ? .orange : .secondary)
            }
        }
    }
    private var subtitle: String {
        var parts: [String] = []
        if !medication.dose.isEmpty { parts.append(medication.dose) }
        parts.append(medication.dosesPerDay == 1 ? "once a day" : "\(trim(medication.dosesPerDay))× a day")
        parts.append("\(trim(medication.unitsOnHand)) on hand")
        return parts.joined(separator: " · ")
    }
    private func trim(_ d: Double) -> String { d == d.rounded() ? String(Int(d)) : String(format: "%.1f", d) }
}

struct MedicationEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let person: Person
    private let existing: Medication?

    @State private var name: String
    @State private var dose: String
    @State private var dosesPerDay: Double
    @State private var unitsPerDose: Double
    @State private var unitsOnHand: Double
    @State private var isCritical: Bool
    @State private var hasExpiration: Bool
    @State private var expirationDate: Date
    @State private var notes: String

    init(person: Person, medication: Medication? = nil) {
        self.person = person
        self.existing = medication
        _name = State(initialValue: medication?.name ?? "")
        _dose = State(initialValue: medication?.dose ?? "")
        _dosesPerDay = State(initialValue: medication?.dosesPerDay ?? 1)
        _unitsPerDose = State(initialValue: medication?.unitsPerDose ?? 1)
        _unitsOnHand = State(initialValue: medication?.unitsOnHand ?? 30)
        _isCritical = State(initialValue: medication?.isCritical ?? false)
        _hasExpiration = State(initialValue: medication?.expirationDate != nil)
        _expirationDate = State(initialValue: medication?.expirationDate ?? Date())
        _notes = State(initialValue: medication?.notes ?? "")
    }

    private var days: Double? {
        let perDay = dosesPerDay * unitsPerDose
        return perDay > 0 ? unitsOnHand / perDay : nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name (e.g. Metformin)", text: $name)
                    TextField("Dose (e.g. 500 mg, 1 puff)", text: $dose)
                    HStack {
                        Text("Times a day")
                        Spacer()
                        TextField("1", value: $dosesPerDay, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 80)
                    }
                    HStack {
                        Text("Tablets or units per dose")
                        Spacer()
                        TextField("1", value: $unitsPerDose, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 80)
                    }
                    HStack {
                        Text("On hand")
                        Spacer()
                        TextField("30", value: $unitsOnHand, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 80)
                    }
                    if let d = days {
                        LabeledContent("Days of supply", value: ReadinessCalculator.formatDays(d))
                    }
                }
                Section {
                    Toggle("Can't miss a day", isOn: $isCritical)
                } footer: {
                    Text("Insulin, seizure, heart, thyroid, inhalers. Flagged medications get a louder reminder and an early place on the shopping list.")
                }
                Section("Dates and notes") {
                    Toggle("Expiration date", isOn: $hasExpiration)
                    if hasExpiration { DatePicker("Expires", selection: $expirationDate, displayedComponents: .date) }
                    TextField("Pharmacy, prescriber, refill rules", text: $notes, axis: .vertical).lineLimit(2...4)
                }
            }
            .navigationTitle(existing == nil ? "Add medication" : "Edit medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let m = existing ?? Medication(name: name)
        m.name = name.trimmingCharacters(in: .whitespaces)
        m.dose = dose
        m.dosesPerDay = max(0, dosesPerDay)
        m.unitsPerDose = max(0, unitsPerDose)
        m.unitsOnHand = max(0, unitsOnHand)
        m.isCritical = isCritical
        m.expirationDate = hasExpiration ? expirationDate : nil
        m.notes = notes
        if existing == nil {
            m.person = person
            context.insert(m)
        }
        try? context.save()
        dismiss()
    }
}
