import SwiftUI
import SwiftData

/// One storage location: name, symbol, how to find things there, and, for a place away from the house,
/// an address and coordinates.
struct LocationEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \StorageLocation.sortOrder) private var locations: [StorageLocation]

    private let existing: StorageLocation?
    @State private var name: String
    @State private var symbol: String
    @State private var notes: String
    @State private var address: String
    @State private var latitude: Double?
    @State private var longitude: Double?
    @State private var photo: Data?
    @State private var addingItem = false
    @State private var confirmDelete = false

    static let symbols: [(String, String)] = [
        ("cabinet.fill", "Pantry"), ("shippingbox.fill", "Shelf"), ("backpack.fill", "Go-bag"), ("car.fill", "Car"),
        ("cross.case.fill", "Medicine"), ("house.fill", "House"), ("snowflake", "Freezer"), ("archivebox.fill", "Bin"),
        ("building.2.fill", "Storage unit"), ("tent.fill", "Camp"), ("sailboat.fill", "Boat"), ("tree.fill", "Outdoors"),
        ("door.garage.closed", "Garage"), ("bed.double.fill", "Bedroom"), ("briefcase.fill", "Office"), ("house.lodge.fill", "Cabin"),
    ]

    init(location: StorageLocation? = nil) {
        existing = location
        _name = State(initialValue: location?.name ?? "")
        _symbol = State(initialValue: location?.symbol ?? "shippingbox.fill")
        _notes = State(initialValue: location?.notes ?? "")
        _address = State(initialValue: location?.address ?? "")
        _latitude = State(initialValue: location?.latitude)
        _longitude = State(initialValue: location?.longitude)
        _photo = State(initialValue: location?.photo)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name (Hall closet, Mom's garage, the cabin)", text: $name)
                    TextField("How to find things here (top shelf, behind the paint cans)", text: $notes, axis: .vertical)
                    PhotoPickerButton(photoData: $photo)
                } header: { Text("Location") } footer: {
                    Text("A photo and one line of directions get a babysitter or a teenager to the right shelf with a flashlight.")
                }

                Section("Symbol") {
                    let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
                    LazyVGrid(columns: cols, spacing: 10) {
                        ForEach(LocationEditView.symbols, id: \.0) { s, label in
                            Button { symbol = s } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: s).font(.title3).frame(height: 26)
                                    Text(label).font(.caption2).lineLimit(1)
                                }
                                .frame(maxWidth: .infinity, minHeight: 58)
                                .background(symbol == s ? Color.ink.opacity(0.12) : Color(uiColor: .tertiarySystemFill), in: RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(symbol == s ? Color.ink : Color.clear, lineWidth: 2))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(symbol == s ? Color.ink : Color.primary)
                            .accessibilityLabel(label)
                            .accessibilityAddTraits(symbol == s ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    TextField("Address or landmark (optional)", text: $address, axis: .vertical)
                } header: { Text("Away from home") } footer: {
                    Text("For a storage unit, a relative's house, a cabin or a boat. Leave it blank for a room in the house.")
                }

                CoordinateSection(title: "Coordinates", latitude: $latitude, longitude: $longitude)

                if let loc = existing {
                    Section {
                        LabeledContent("Supplies here", value: "\(loc.items.count)")
                        LabeledContent("Gear here", value: "\(loc.equipment.count)")
                        Button { addingItem = true } label: { Label("Add a supply here", systemImage: "plus") }
                        Button("Delete this location", role: .destructive) { confirmDelete = true }
                    } footer: {
                        Text("Deleting a location keeps its items; they just lose the label.")
                    }
                }
            }
            .navigationTitle(existing == nil ? "New location" : "Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.fontWeight(.semibold).disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $addingItem) { if let loc = existing { ItemEditView(draft: ItemDraft(location: loc)) } }
            .confirmationDialog("Delete \(name)?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) { if let loc = existing { context.delete(loc); try? context.save() }; dismiss() }
            } message: { Text("Its supplies stay in the list without a location.") }
        }
    }

    private func save() {
        let loc = existing ?? StorageLocation(name: "", symbol: symbol, sortOrder: locations.count)
        loc.name = name.trimmingCharacters(in: .whitespaces)
        loc.symbol = symbol
        loc.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        loc.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        loc.latitude = latitude
        loc.longitude = longitude
        loc.photo = photo
        if existing == nil { context.insert(loc) }
        try? context.save()
        dismiss()
    }
}
