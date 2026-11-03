import SwiftUI
import SwiftData

struct PetEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let household: Household
    private let existing: Pet?

    @State private var name: String
    @State private var species: PetSpecies
    @State private var weightLb: Double?
    @State private var medications: String
    @State private var notes: String

    init(household: Household, pet: Pet? = nil) {
        self.household = household
        self.existing = pet
        _name = State(initialValue: pet?.name ?? "")
        _species = State(initialValue: pet?.species ?? .dog)
        _weightLb = State(initialValue: pet?.weightKg.map { ($0 * 2.20462).rounded() })
        _medications = State(initialValue: pet?.medications ?? "")
        _notes = State(initialValue: pet?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    Picker("Kind", selection: $species) { ForEach(PetSpecies.allCases) { Text($0.title).tag($0) } }
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("lb", value: $weightLb, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 90)
                        Text("lb").foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("Weight sets the water estimate: about an ounce per pound per day.")
                }
                Section("Notes") {
                    TextField("Medications", text: $medications, axis: .vertical)
                    TextField("Vet, microchip, food brand, carrier location", text: $notes, axis: .vertical).lineLimit(2...4)
                }
            }
            .navigationTitle(existing == nil ? "Add a pet" : "Edit pet")
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
        let p = existing ?? Pet(name: name)
        p.name = name.trimmingCharacters(in: .whitespaces)
        p.species = species
        p.weightKg = weightLb.map { $0 / 2.20462 }
        p.medications = medications
        p.notes = notes
        if existing == nil {
            p.household = household
            context.insert(p)
        }
        try? context.save()
        dismiss()
    }
}
