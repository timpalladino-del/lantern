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

    init(household: Household, person: Person? = nil, initialName: String = "") {
        self.household = household
        self.existing = person
        _name = State(initialValue: person?.name ?? initialName)
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
                    if let p = existing, !PlanStore.shared.coversPerson(at: household.sortedPeople.firstIndex { $0.uuid == p.uuid } ?? 0) {
                        LockedRow(title: "Medications for \(p.name) are part of Family", reason: .feature("Tracking everyone's medications"))
                    } else if let p = existing {
                        ForEach(p.medications.sorted { $0.createdAt < $1.createdAt }, id: \.uuid) { m in
                            Button { editingMedication = m } label: { MedicationRow(medication: m) }
                                .foregroundStyle(.primary)
                                .swipeActions {
                                    Button(role: .destructive) { context.delete(m); try? context.save() } label: { Label("Delete", systemImage: "trash") }
                                }
                        }
                        Button { showNewMedication = true } label: { Label("Add a medication", systemImage: "plus") }
                        if !p.medications.isEmpty {
                            ShareLink(item: MedicationCardView.cardText(for: [p]), subject: Text("\(p.name)'s medication card")) {
                                Label("Share \(p.name)'s medication card", systemImage: "square.and.arrow.up")
                            }
                        }
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
            // The person is kept either way; readiness needs them. The offer comes after this sheet closes.
            if let reason = PlanStore.shared.reasonForAdding(personNumber: household.people.count) {
                PlanStore.shared.pendingPaywall = reason
            }
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
                    if medication.isCritical { Image(systemName: "exclamationmark.circle.fill").foregroundStyle(Color.ember).font(.caption) }
                }
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if let d = medication.daysOfSupply {
                Text(ReadinessCalculator.formatDays(d))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(d < 7 ? Color.ember : Color.secondary)
            }
        }
    }
    private var subtitle: String {
        var parts: [String] = []
        if !medication.dose.isEmpty { parts.append(medication.dose) }
        parts.append(medication.scheduleSummary)
        parts.append("\(trim(medication.unitsOnHand)) on hand")
        return parts.joined(separator: " · ")
    }
    private func trim(_ d: Double) -> String { d == d.rounded() ? String(Int(d)) : String(format: "%.1f", d) }
}
