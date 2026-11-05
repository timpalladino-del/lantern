import SwiftUI
import SwiftData

/// Everything on the pharmacy label plus the things people forget to say out loud: when it is taken,
/// how, and what to avoid. The card view prints exactly this.
struct MedicationEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let person: Person
    private let existing: Medication?

    @State private var name: String
    @State private var dose: String
    @State private var form: MedicationForm
    @State private var purpose: String
    @State private var dosesPerDay: Double
    @State private var unitsPerDose: Double
    @State private var unitsOnHand: Double
    @State private var isCritical: Bool
    @State private var hasExpiration: Bool
    @State private var expirationDate: Date
    @State private var notes: String
    @State private var times: [Date]
    @State private var instructionKeys: Set<String>
    @State private var customInstructions: String
    @State private var prescriber: String
    @State private var prescriberPhone: String
    @State private var pharmacy: String
    @State private var pharmacyPhone: String
    @State private var rxNumber: String
    @State private var remindersEnabled: Bool
    @State private var showInstructionPicker = false
    @State private var showSearch = false
    private let library = MedicationLibrary.shared
    /// Screenshot aid only: open scrolled to a section id ("instructions" or "notes").
    private let scrollTarget: String?

    init(person: Person, medication: Medication? = nil, scrollTarget: String? = nil) {
        self.person = person
        self.existing = medication
        self.scrollTarget = scrollTarget
        _name = State(initialValue: medication?.name ?? "")
        _dose = State(initialValue: medication?.dose ?? "")
        _form = State(initialValue: medication?.form ?? .tablet)
        _purpose = State(initialValue: medication?.purpose ?? "")
        _dosesPerDay = State(initialValue: medication?.dosesPerDay ?? 1)
        _unitsPerDose = State(initialValue: medication?.unitsPerDose ?? 1)
        _unitsOnHand = State(initialValue: medication?.unitsOnHand ?? 30)
        _isCritical = State(initialValue: medication?.isCritical ?? false)
        _hasExpiration = State(initialValue: medication?.expirationDate != nil)
        _expirationDate = State(initialValue: medication?.expirationDate ?? Date())
        _notes = State(initialValue: medication?.notes ?? "")
        _times = State(initialValue: (medication?.scheduleMinutes ?? []).sorted().map { MedicationEditView.date(fromMinutes: $0) })
        _instructionKeys = State(initialValue: Set(medication?.instructionKeys ?? []))
        _customInstructions = State(initialValue: medication?.customInstructions ?? "")
        _prescriber = State(initialValue: medication?.prescriber ?? "")
        _prescriberPhone = State(initialValue: medication?.prescriberPhone ?? "")
        _pharmacy = State(initialValue: medication?.pharmacy ?? "")
        _pharmacyPhone = State(initialValue: medication?.pharmacyPhone ?? "")
        _rxNumber = State(initialValue: medication?.rxNumber ?? "")
        _remindersEnabled = State(initialValue: medication?.remindersEnabled ?? false)
    }

    private var effectiveDosesPerDay: Double { times.isEmpty ? dosesPerDay : Double(times.count) }

    private var days: Double? {
        let perDay = effectiveDosesPerDay * unitsPerDose
        return perDay > 0 ? unitsOnHand / perDay : nil
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
            Form {
                Section {
                    Button { showSearch = true } label: { Label("Find it in the list", systemImage: "magnifyingglass") }
                    TextField("Name (e.g. Metformin)", text: $name)
                    if name.count >= 3, !library.search(name, limit: 1).contains(where: { $0.generic.lowercased() == name.lowercased() || $0.displayName.lowercased() == name.lowercased() }) {
                        ForEach(library.search(name, limit: 3)) { e in
                            Button { apply(e) } label: {
                                HStack {
                                    Image(systemName: "arrow.turn.down.right").foregroundStyle(.secondary)
                                    Text(e.displayName).foregroundStyle(.primary)
                                    Spacer()
                                    Text(e.purpose).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    TextField("Strength (e.g. 500 mg, 1 puff)", text: $dose)
                    Picker("Form", selection: $form) {
                        ForEach(MedicationForm.allCases) { f in Text(f.title).tag(f) }
                    }
                    TextField("What it is for (e.g. blood pressure)", text: $purpose)
                } header: { Text("What") } footer: {
                    Text("Search by name, brand or what it's for. Spelling doesn't have to be right.")
                }

                Section {
                    ForEach(times.indices, id: \.self) { i in
                        DatePicker("Dose \(i + 1)", selection: $times[i], displayedComponents: .hourAndMinute)
                            .swipeActions { Button(role: .destructive) { times.remove(at: i) } label: { Label("Remove", systemImage: "trash") } }
                    }
                    .onDelete { times.remove(atOffsets: $0) }
                    Button { addTime() } label: { Label("Add a time", systemImage: "plus.circle") }
                    if times.isEmpty {
                        HStack {
                            Text("Times a day")
                            Spacer()
                            TextField("1", value: $dosesPerDay, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 80)
                        }
                    }
                    HStack {
                        Text("\(form.unitName.capitalized) per dose")
                        Spacer()
                        TextField("1", value: $unitsPerDose, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 80)
                    }
                    Toggle("Remind me at these times", isOn: $remindersEnabled).disabled(times.isEmpty)
                } header: { Text("When") } footer: {
                    Text(times.isEmpty
                         ? "Add the clock times it is taken and the card can show them to whoever is helping. Set times a day to 0 for as-needed medication."
                         : "Reminders are local notifications on this phone only.")
                }

                Section {
                    ForEach(MedicationInstruction.Kind.allCases, id: \.self) { kind in
                        let chosen = MedicationInstruction.all(of: kind).filter { instructionKeys.contains($0.rawValue) }
                        if !chosen.isEmpty {
                            ForEach(chosen) { ins in
                                Label(ins.title, systemImage: ins.symbol)
                                    .foregroundStyle(kind == .warning ? Color.ember : Color.primary)
                                    .swipeActions { Button(role: .destructive) { instructionKeys.remove(ins.rawValue) } label: { Label("Remove", systemImage: "trash") } }
                            }
                        }
                    }
                    Button { showInstructionPicker = true } label: { Label("Choose from the label", systemImage: "list.bullet.clipboard") }
                    TextField("Anything else (e.g. skip if dizzy)", text: $customInstructions, axis: .vertical).lineLimit(1...3)
                } header: { Text("How to take it, and what to avoid") } footer: {
                    Text("Take with food, do not drive, avoid alcohol. These print on the medication card so the person helping does not have to guess.")
                }
                .id("instructions")

                Section("Supply") {
                    HStack {
                        Text("On hand")
                        Spacer()
                        TextField("30", value: $unitsOnHand, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 80)
                    }
                    if let d = days {
                        LabeledContent("Days of supply", value: ReadinessCalculator.formatDays(d))
                    }
                    Toggle("Can't miss a day", isOn: $isCritical)
                    Toggle("Expiration date", isOn: $hasExpiration)
                    if hasExpiration { DatePicker("Expires", selection: $expirationDate, displayedComponents: .date) }
                }

                Section("Prescriber and pharmacy") {
                    TextField("Prescriber (Dr. Alvarez)", text: $prescriber)
                    TextField("Prescriber phone", text: $prescriberPhone).keyboardType(.phonePad)
                    TextField("Pharmacy (CVS on Main St)", text: $pharmacy)
                    TextField("Pharmacy phone", text: $pharmacyPhone).keyboardType(.phonePad)
                    TextField("Rx number", text: $rxNumber)
                }

                Section("Notes") {
                    TextField("Refill rules, what a missed dose means, anything else", text: $notes, axis: .vertical).lineLimit(2...4)
                }
                .id("notes")
            }
            .onAppear {
                if let target = scrollTarget {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { proxy.scrollTo(target, anchor: target == "notes" ? .bottom : .top) }
                }
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
            .sheet(isPresented: $showInstructionPicker) {
                InstructionPicker(selected: $instructionKeys)
            }
            .sheet(isPresented: $showSearch) {
                MedicationSearchView { apply($0) }
            }
        }
    }

    /// Fill the form from a library entry. Keeps anything the person already typed for dose and purpose.
    private func apply(_ e: MedicationEntry) {
        name = e.displayName
        if dose.isEmpty, let first = e.strengths.first, first != "as needed" { dose = first }
        if purpose.isEmpty { purpose = e.purpose }
        form = e.medicationForm
        for k in e.instructionKeys { instructionKeys.insert(k) }
        if existing == nil, e.critical { isCritical = true }
        if e.purpose.lowercased().contains("as needed") || e.strengths == ["as needed"] { dosesPerDay = 0 }
    }

    private func addTime() {
        // Sensible defaults: 8 AM, then 8 PM, then noon, then 4 PM.
        let defaults = [8 * 60, 20 * 60, 12 * 60, 16 * 60, 22 * 60]
        let used = Set(times.map { MedicationEditView.minutes(from: $0) })
        let next = defaults.first { !used.contains($0) } ?? 9 * 60
        times.append(MedicationEditView.date(fromMinutes: next))
    }

    static func date(fromMinutes m: Int) -> Date {
        Calendar.current.date(bySettingHour: m / 60, minute: m % 60, second: 0, of: Date()) ?? Date()
    }

    static func minutes(from date: Date) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    private func save() {
        let m = existing ?? Medication(name: name)
        m.name = name.trimmingCharacters(in: .whitespaces)
        m.dose = dose
        m.form = form
        m.purpose = purpose
        m.scheduleMinutes = Array(Set(times.map { MedicationEditView.minutes(from: $0) })).sorted()
        m.dosesPerDay = max(0, effectiveDosesPerDay)
        m.unitsPerDose = max(0, unitsPerDose)
        m.unitsOnHand = max(0, unitsOnHand)
        m.isCritical = isCritical
        m.expirationDate = hasExpiration ? expirationDate : nil
        m.instructionKeys = MedicationInstruction.allCases.map(\.rawValue).filter { instructionKeys.contains($0) }
        m.customInstructions = customInstructions.trimmingCharacters(in: .whitespacesAndNewlines)
        m.prescriber = prescriber
        m.prescriberPhone = prescriberPhone
        m.pharmacy = pharmacy
        m.pharmacyPhone = pharmacyPhone
        m.rxNumber = rxNumber
        m.remindersEnabled = remindersEnabled && !m.scheduleMinutes.isEmpty
        m.notes = notes
        if existing == nil {
            m.person = person
            context.insert(m)
        }
        try? context.save()
        Task { await NotificationScheduler.shared.scheduleMedicationReminders(for: person.household?.sortedPeople.flatMap(\.medications) ?? [m]) }
        dismiss()
    }
}

/// Tappable list of standard label instructions, grouped into how-to-take and warnings.
struct InstructionPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selected: Set<String>

    var body: some View {
        NavigationStack {
            List {
                ForEach(MedicationInstruction.Kind.allCases, id: \.self) { kind in
                    Section(kind.rawValue) {
                        ForEach(MedicationInstruction.all(of: kind)) { ins in
                            Button {
                                if selected.contains(ins.rawValue) { selected.remove(ins.rawValue) } else { selected.insert(ins.rawValue) }
                            } label: {
                                HStack {
                                    Label(ins.title, systemImage: ins.symbol).foregroundStyle(.primary)
                                    Spacer()
                                    if selected.contains(ins.rawValue) {
                                        Image(systemName: "checkmark").foregroundStyle(Color.ink).fontWeight(.semibold)
                                    }
                                }
                            }
                            .accessibilityAddTraits(selected.contains(ins.rawValue) ? .isSelected : [])
                        }
                    }
                }
            }
            .navigationTitle("From the label")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
