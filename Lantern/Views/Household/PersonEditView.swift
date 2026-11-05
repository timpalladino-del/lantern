import SwiftUI
import SwiftData

/// Add or edit one person. Weight and height are optional and in US units on screen.
/// Beyond the basics: contact, health, what runs on power, skills, wellness, and any field they want to add.
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

    @State private var phone: String
    @State private var emergencyContactName: String
    @State private var emergencyContactPhone: String
    @State private var bloodType: BloodType
    @State private var conditions: String
    @State private var mobility: Mobility
    @State private var powerDeviceKeys: Set<String>
    @State private var wellnessNotes: String
    @State private var comfortNeeds: String
    @State private var skillKeys: Set<String>
    @State private var languages: String
    @State private var canDrive: Bool
    @State private var emergencyRole: String
    @State private var customFields: [CustomField]

    @State private var editingMedication: Medication?
    @State private var showNewMedication = false
    @State private var showSkills = false
    @State private var showDevices = false
    @State private var newFieldLabel = ""
    @State private var showNewField = false

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
        _phone = State(initialValue: person?.phone ?? "")
        _emergencyContactName = State(initialValue: person?.emergencyContactName ?? "")
        _emergencyContactPhone = State(initialValue: person?.emergencyContactPhone ?? "")
        _bloodType = State(initialValue: person?.bloodType ?? .unknown)
        _conditions = State(initialValue: person?.conditions ?? "")
        _mobility = State(initialValue: person?.mobility ?? .independent)
        _powerDeviceKeys = State(initialValue: Set(person?.powerDeviceKeys ?? []))
        _wellnessNotes = State(initialValue: person?.wellnessNotes ?? "")
        _comfortNeeds = State(initialValue: person?.comfortNeeds ?? "")
        _skillKeys = State(initialValue: Set(person?.skillKeys ?? []))
        _languages = State(initialValue: person?.languages ?? "")
        _canDrive = State(initialValue: person?.canDrive ?? false)
        _emergencyRole = State(initialValue: person?.emergencyRole ?? "")
        _customFields = State(initialValue: person?.customFields ?? [])
    }

    private var previewCalories: Double {
        let kg = weightLb.map { $0 / 2.20462 }
        let cm: Double? = hasHeight ? Double(heightFt * 12 + heightIn) * 2.54 : nil
        return CalorieEstimator.dailyCalories(age: hasAge ? age : nil, weightKg: kg, heightCm: cm, sex: sex, activity: activity)
    }

    private var skillTitles: [String] { SkillLibrary.all.filter { skillKeys.contains($0.key) }.map(\.title) }
    private var deviceTitles: [String] { PowerDevice.all.filter { powerDeviceKeys.contains($0.key) }.map(\.title) }

    var body: some View {
        NavigationStack {
            Form {
                basics
                size
                food
                contact
                medications
                health
                powerSection
                skillsSection
                wellness
                emergency
                more
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
            .sheet(isPresented: $showSkills) {
                MultiPickSheet(title: "Skills", groups: SkillGroup.allCases.map { g in
                    (g.rawValue, SkillLibrary.all.filter { $0.group == g }.map { ($0.key, $0.title, $0.symbol) })
                }, selection: $skillKeys)
            }
            .sheet(isPresented: $showDevices) {
                MultiPickSheet(title: "Runs on power", groups: [("", PowerDevice.all.map { ($0.key, $0.title, "bolt.fill") })], selection: $powerDeviceKeys)
            }
            .alert("Add a field", isPresented: $showNewField) {
                TextField("Label (e.g. Glasses prescription)", text: $newFieldLabel)
                Button("Add") {
                    let l = newFieldLabel.trimmingCharacters(in: .whitespaces)
                    if !l.isEmpty { customFields.append(CustomField(label: l, value: "")) }
                    newFieldLabel = ""
                }
                Button("Cancel", role: .cancel) { newFieldLabel = "" }
            } message: {
                Text("Anything worth knowing that the app did not ask for.")
            }
        }
    }

    // MARK: Sections

    private var basics: some View {
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
    }

    private var size: some View {
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
    }

    private var food: some View {
        Section {
            if hasAge && age < 1 {
                Label("Under one: counted as formula or stored milk, not calories.", systemImage: "info.circle")
                    .font(.subheadline)
            } else {
                LabeledContent("Needs about", value: "\(Int(previewCalories.rounded())) calories a day")
            }
            TextField("Allergies (peanuts, penicillin, bee stings…)", text: $allergies, axis: .vertical)
            TextField("Diet (vegetarian, gluten-free, diabetic…)", text: $dietaryNotes, axis: .vertical)
        } header: { Text("Food") } footer: {
            Text("Mifflin-St Jeor when weight and height are known, otherwise USDA Dietary Guidelines bands. A planning number, not medical advice.")
        }
    }

    private var contact: some View {
        Section("Contact") {
            TextField("Phone", text: $phone).keyboardType(.phonePad)
            TextField("Someone to call about them (name)", text: $emergencyContactName)
            TextField("Their phone", text: $emergencyContactPhone).keyboardType(.phonePad)
        }
    }

    private var medications: some View {
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
    }

    private var health: some View {
        Section {
            Picker("Blood type", selection: $bloodType) {
                ForEach(BloodType.allCases) { Text($0.title).tag($0) }
            }
            TextField("Conditions (asthma, diabetes, heart, seizures…)", text: $conditions, axis: .vertical)
            Picker("Mobility", selection: $mobility) {
                ForEach(Mobility.allCases) { Text($0.title).tag($0) }
            }
        } header: { Text("Health") } footer: {
            Text("Goes on the medication card so a neighbor or paramedic has it in one place.")
        }
    }

    private var powerSection: some View {
        Section {
            Button { showDevices = true } label: {
                HStack {
                    Text(deviceTitles.isEmpty ? "Nothing that needs power" : deviceTitles.joined(separator: ", "))
                        .foregroundStyle(deviceTitles.isEmpty ? .secondary : .primary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                }
            }
            .foregroundStyle(.primary)
            ForEach(PowerDevice.all.filter { powerDeviceKeys.contains($0.key) }) { d in
                Text(d.hint).font(.footnote).foregroundStyle(.secondary)
            }
        } header: { Text("Runs on power") } footer: {
            Text("CPAP, oxygen, insulin in the fridge. These decide how long an outage can safely last.")
        }
    }

    private var skillsSection: some View {
        Section {
            Button { showSkills = true } label: {
                HStack {
                    Text(skillTitles.isEmpty ? "Pick what \(name.isEmpty ? "they" : name) can do" : skillTitles.joined(separator: ", "))
                        .foregroundStyle(skillTitles.isEmpty ? .secondary : .primary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                }
            }
            .foregroundStyle(.primary)
            TextField("Languages spoken", text: $languages)
            Toggle("Can drive", isOn: $canDrive)
        } header: { Text("Skills") } footer: {
            Text("First aid, the generator, the gas shutoff. Knowing who can do what is half of a plan.")
        }
    }

    private var wellness: some View {
        Section {
            TextField("Mental health, anxiety, sensory needs, routines that matter", text: $wellnessNotes, axis: .vertical).lineLimit(2...5)
            TextField("What helps when things are hard (music, a quiet room, a specific toy)", text: $comfortNeeds, axis: .vertical).lineLimit(2...5)
        } header: { Text("Wellness") } footer: {
            Text("Long outages and evacuations are hard on everyone. Write down what keeps this person steady.")
        }
    }

    private var emergency: some View {
        Section {
            TextField("Their job when something happens", text: $emergencyRole, axis: .vertical)
            TextField("Anything else worth knowing in a bad week", text: $notes, axis: .vertical).lineLimit(2...5)
        } header: { Text("In an emergency") } footer: {
            Text("\"Grabs the dog and the go-bag.\" \"Shuts off the gas.\" \"Calls Aunt Pat.\" Everyone gets one line.")
        }
    }

    private var more: some View {
        Section {
            ForEach($customFields) { $field in
                VStack(alignment: .leading, spacing: 2) {
                    Text(field.label).font(.caption).foregroundStyle(.secondary)
                    TextField("Value", text: $field.value, axis: .vertical)
                }
            }
            .onDelete { customFields.remove(atOffsets: $0) }
            Button { showNewField = true } label: { Label("Add a field", systemImage: "plus") }
        } header: { Text("More") } footer: {
            Text("Glasses prescription, shoe size, school, employer, passport number. Whatever you would want written down.")
        }
    }

    // MARK: Save

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
        p.phone = phone
        p.emergencyContactName = emergencyContactName
        p.emergencyContactPhone = emergencyContactPhone
        p.bloodType = bloodType
        p.conditions = conditions
        p.mobility = mobility
        p.powerDeviceKeys = PowerDevice.all.map(\.key).filter { powerDeviceKeys.contains($0) }
        p.wellnessNotes = wellnessNotes
        p.comfortNeeds = comfortNeeds
        p.skillKeys = SkillLibrary.all.map(\.key).filter { skillKeys.contains($0) }
        p.languages = languages
        p.canDrive = canDrive
        p.emergencyRole = emergencyRole
        p.customFields = customFields.filter { !$0.label.trimmingCharacters(in: .whitespaces).isEmpty }
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

/// Checklist picker for skills and power devices. Grouped, searchable by eye, nothing clever.
struct MultiPickSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    /// (group title, [(key, title, symbol)])
    let groups: [(String, [(String, String, String)])]
    @Binding var selection: Set<String>

    var body: some View {
        NavigationStack {
            List {
                ForEach(groups, id: \.0) { group in
                    Section(group.0) {
                        ForEach(group.1, id: \.0) { key, title, symbol in
                            Button {
                                if selection.contains(key) { selection.remove(key) } else { selection.insert(key) }
                            } label: {
                                HStack {
                                    Label(title, systemImage: symbol)
                                    Spacer()
                                    if selection.contains(key) {
                                        Image(systemName: "checkmark").foregroundStyle(Color.ink).fontWeight(.semibold)
                                    }
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
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
