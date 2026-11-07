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
    @State private var cups: Double?
    @State private var cans: Double?
    @State private var foodBrand: String
    @State private var prescriptionDiet: Bool
    @State private var microchip: String
    @State private var microchipRegistry: String
    @State private var vet: String
    @State private var vetPhone: String
    @State private var carrierLocation: String
    @State private var caregiverName: String
    @State private var caregiverPhone: String
    @State private var lodgingNotes: String
    @State private var vaccinationPhoto: Data?

    init(household: Household, pet: Pet? = nil) {
        self.household = household
        self.existing = pet
        _name = State(initialValue: pet?.name ?? "")
        _species = State(initialValue: pet?.species ?? .dog)
        _weightLb = State(initialValue: pet?.weightKg.map { ($0 * 2.20462).rounded() })
        _medications = State(initialValue: pet?.medications ?? "")
        _notes = State(initialValue: pet?.notes ?? "")
        _cups = State(initialValue: pet?.foodCupsPerDay)
        _cans = State(initialValue: pet?.foodCansPerDay)
        _foodBrand = State(initialValue: pet?.foodBrand ?? "")
        _prescriptionDiet = State(initialValue: pet?.prescriptionDiet ?? false)
        _microchip = State(initialValue: pet?.microchip ?? "")
        _microchipRegistry = State(initialValue: pet?.microchipRegistry ?? "")
        _vet = State(initialValue: pet?.vet ?? "")
        _vetPhone = State(initialValue: pet?.vetPhone ?? "")
        _carrierLocation = State(initialValue: pet?.carrierLocation ?? "")
        _caregiverName = State(initialValue: pet?.caregiverName ?? "")
        _caregiverPhone = State(initialValue: pet?.caregiverPhone ?? "")
        _lodgingNotes = State(initialValue: pet?.lodgingNotes ?? "")
        _vaccinationPhoto = State(initialValue: pet?.vaccinationPhotoData)
    }

    private var previewKcal: Double {
        let fed = (cups ?? 0) * Pet.kcalPerCupDry + (cans ?? 0) * Pet.kcalPerCanWet
        if fed > 0 { return fed }
        let kg = (weightLb ?? species.defaultWeightKg * 2.20462) / 2.20462
        let rer = 70 * pow(max(0.5, kg), 0.75)
        return rer * (species == .dog ? 1.6 : species == .cat ? 1.2 : 1.4)
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
                Section {
                    HStack {
                        Text("Dry food, cups a day")
                        Spacer()
                        TextField("2", value: $cups, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 80)
                    }
                    HStack {
                        Text("Wet food, cans a day")
                        Spacer()
                        TextField("0", value: $cans, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 80)
                    }
                    TextField("Brand and flavor (so you buy the right one)", text: $foodBrand)
                    Toggle("Prescription or special diet", isOn: $prescriptionDiet)
                    LabeledContent("About", value: "\(Int(previewKcal.rounded())) calories a day")
                } header: { Text("Food") } footer: {
                    Text(((cups ?? 0) + (cans ?? 0)) > 0
                         ? "A cup of dry food is about 350 calories, a 13 oz can about 400. Pet food in Supplies is counted against this."
                         : "Estimated from weight until you enter cups or cans. Pet food in Supplies is counted against this.")
                }
                Section {
                    TextField("Microchip number", text: $microchip).keyboardType(.numbersAndPunctuation)
                    TextField("Registered with (HomeAgain, AKC Reunite)", text: $microchipRegistry)
                    TextField("Vet", text: $vet)
                    TextField("Vet phone", text: $vetPhone).keyboardType(.phonePad)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Vaccination record").font(.subheadline)
                        PhotoPickerButton(photoData: $vaccinationPhoto)
                    }
                } header: { Text("Records") } footer: {
                    Text("Shelters that take pets ask for current vaccination records. Check that the chip registry has your current phone number; most do not.")
                }
                Section {
                    TextField("Carrier or crate: where it is", text: $carrierLocation, axis: .vertical)
                    TextField("Who takes \(name.isEmpty ? "them" : name) if we can't", text: $caregiverName)
                    TextField("Their phone", text: $caregiverPhone).keyboardType(.phonePad)
                    TextField("Pet-friendly places we could go", text: $lodgingNotes, axis: .vertical).lineLimit(2...4)
                } header: { Text("If we have to leave") } footer: {
                    Text("Pet-friendly rooms fill within hours of a warning. Pick two now and write them here. A photo of you with \(name.isEmpty ? "your pet" : name) proves ownership if you are separated.")
                }
                Section("Notes") {
                    TextField("Medications", text: $medications, axis: .vertical)
                    TextField("Anything else: habits, fears, food allergies", text: $notes, axis: .vertical).lineLimit(2...4)
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
        p.foodCupsPerDay = cups
        p.foodCansPerDay = cans
        p.foodBrand = foodBrand
        p.prescriptionDiet = prescriptionDiet
        p.microchip = microchip.trimmingCharacters(in: .whitespaces)
        p.microchipRegistry = microchipRegistry
        p.vet = vet
        p.vetPhone = vetPhone
        p.carrierLocation = carrierLocation
        p.caregiverName = caregiverName
        p.caregiverPhone = caregiverPhone
        p.lodgingNotes = lodgingNotes
        p.vaccinationPhotoData = vaccinationPhoto
        if existing == nil {
            p.household = household
            context.insert(p)
        }
        try? context.save()
        dismiss()
    }
}
