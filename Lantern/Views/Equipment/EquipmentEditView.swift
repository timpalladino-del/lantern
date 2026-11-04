import SwiftUI
import SwiftData

struct EquipmentEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \StorageLocation.sortOrder) private var locations: [StorageLocation]

    private let existing: Equipment?
    private let library = MaintenanceLibrary.shared

    @State private var name: String
    @State private var kind: String
    @State private var brand: String
    @State private var model: String
    @State private var serial: String
    @State private var location: StorageLocation?
    @State private var hasPurchaseDate: Bool
    @State private var purchaseDate: Date
    @State private var hasManufactureDate: Bool
    @State private var manufactureDate: Date
    @State private var fuelType: String
    @State private var batteryType: String
    @State private var batteryCount: Int
    @State private var notes: String
    @State private var photoData: Data?
    @State private var addDefaultTasks = true
    @State private var details: [String: String]

    init(equipment: Equipment? = nil) {
        existing = equipment
        let now = Date()
        _name = State(initialValue: equipment?.name ?? "")
        _kind = State(initialValue: equipment?.kindRaw ?? "generator")
        _brand = State(initialValue: equipment?.brand ?? "")
        _model = State(initialValue: equipment?.model ?? "")
        _serial = State(initialValue: equipment?.serial ?? "")
        _location = State(initialValue: equipment?.location)
        _hasPurchaseDate = State(initialValue: equipment?.purchaseDate != nil)
        _purchaseDate = State(initialValue: equipment?.purchaseDate ?? now)
        _hasManufactureDate = State(initialValue: equipment?.manufactureDate != nil)
        _manufactureDate = State(initialValue: equipment?.manufactureDate ?? now)
        _fuelType = State(initialValue: equipment?.fuelType ?? "")
        _batteryType = State(initialValue: equipment?.batteryType ?? "")
        _batteryCount = State(initialValue: equipment?.batteryCount ?? 0)
        _notes = State(initialValue: equipment?.notes ?? "")
        _photoData = State(initialValue: equipment?.photoData)
        _details = State(initialValue: equipment?.details ?? [:])
    }

    private var kindInfo: EquipmentKind? { library.kind(kind) }
    private var profile: EquipmentProfile { EquipmentProfile.profile(for: kind) }

    private func binding(_ q: EquipmentQuestion) -> Binding<String> {
        Binding(get: { details[q.key] ?? "" }, set: { details[q.key] = $0 })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(profile.namePlaceholder, text: $name)
                    Picker("Kind", selection: $kind) {
                        ForEach(library.kinds) { k in Label(k.name, systemImage: k.symbol).tag(k.kind) }
                    }
                    .onChange(of: kind) { _, new in
                        if name.isEmpty, let k = library.kind(new) { name = k.name }
                    }
                    Picker("Location", selection: $location) {
                        Text("Not set").tag(Optional<StorageLocation>.none)
                        ForEach(locations) { loc in Text(loc.name).tag(Optional(loc)) }
                    }
                }

                if !profile.questions.isEmpty || profile.hint != nil {
                    Section {
                        if let hint = profile.hint {
                            Text(hint).font(.footnote).foregroundStyle(.secondary)
                        }
                        ForEach(profile.questions) { q in
                            switch q.kind {
                            case .text:
                                LabeledContent(q.label) { TextField(q.placeholder, text: binding(q)).multilineTextAlignment(.trailing) }
                            case .number:
                                LabeledContent(q.label) { TextField(q.placeholder, text: binding(q)).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(maxWidth: 120) }
                            case .toggle:
                                Toggle(q.label, isOn: Binding(get: { details[q.key] == "yes" }, set: { details[q.key] = $0 ? "yes" : "no" }))
                            case .choice(let options):
                                Picker(q.label, selection: binding(q)) {
                                    Text("Not set").tag("")
                                    ForEach(options, id: \.self) { Text($0).tag($0) }
                                }
                            }
                        }
                    } header: { Text("About this \(kindInfo?.name.lowercased() ?? "equipment")") }
                }

                let f = profile.fields
                if !f.isDisjoint(with: [.brand, .model, .serial, .batteries]) || kind == "other" {
                    Section("Details") {
                        if f.contains(.brand) { TextField("Brand", text: $brand) }
                        if f.contains(.model) { TextField("Model", text: $model) }
                        if f.contains(.serial) { TextField("Serial number", text: $serial) }
                        if kind == "other" { TextField("Fuel (gas, propane, none)", text: $fuelType) }
                        if f.contains(.batteries) {
                            TextField("Battery type (AA, 9V, CR123)", text: $batteryType)
                            Stepper("Batteries needed: \(batteryCount)", value: $batteryCount, in: 0...48)
                        }
                    }
                }

                if f.contains(.purchaseDate) || f.contains(.manufactureDate) {
                    Section("Dates") {
                        if f.contains(.purchaseDate) {
                            Toggle("Purchase date", isOn: $hasPurchaseDate)
                            if hasPurchaseDate { DatePicker("Bought", selection: $purchaseDate, displayedComponents: .date) }
                        }
                        if f.contains(.manufactureDate) {
                            Toggle("Manufacture date", isOn: $hasManufactureDate)
                            if hasManufactureDate { DatePicker("Made", selection: $manufactureDate, displayedComponents: .date) }
                            if let years = kindInfo?.lifetimeYears {
                                Text("\(kindInfo?.name ?? "This") should be replaced \(years) years after the manufacture date. It is usually printed on the back.")
                                    .font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if existing == nil, let k = kindInfo, !k.tasks.isEmpty {
                    Section("Check schedule") {
                        Toggle("Add the standard checks", isOn: $addDefaultTasks)
                        ForEach(k.tasks, id: \.title) { t in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(t.title).font(.subheadline)
                                Text("Every \(ShelfLifeEntry.humanDays(t.intervalDays))\(t.source.map { " · \($0)" } ?? "")").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Notes") {
                    TextField(profile.notesPlaceholder, text: $notes, axis: .vertical).lineLimit(2...6)
                    PhotoPickerButton(photoData: $photoData)
                }
            }
            .navigationTitle(existing == nil ? "New equipment" : "Edit equipment")
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
        let e = existing ?? Equipment(name: name, kind: kind)
        e.name = name.trimmingCharacters(in: .whitespaces)
        e.kindRaw = kind
        e.brand = brand
        e.model = model
        e.serial = serial
        e.location = location
        e.purchaseDate = hasPurchaseDate ? purchaseDate : nil
        e.manufactureDate = hasManufactureDate ? manufactureDate : nil
        e.fuelType = details["fuel"].map { $0.isEmpty ? fuelType : $0 } ?? fuelType
        e.batteryType = batteryType
        e.batteryCount = batteryCount
        e.details = details.filter { !$0.value.isEmpty }
        e.notes = notes
        e.photoData = photoData
        if existing == nil {
            context.insert(e)
            if addDefaultTasks, let k = kindInfo {
                for t in k.tasks {
                    let task = MaintenanceTask(title: t.title, intervalDays: t.intervalDays, note: t.note ?? "", source: t.source ?? "", anchorDate: Date())
                    task.equipment = e
                    context.insert(task)
                }
            }
        }
        try? context.save()
        dismiss()
    }
}
