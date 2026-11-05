import SwiftUI
import SwiftData

struct LocationsEditView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \StorageLocation.sortOrder) private var locations: [StorageLocation]

    @State private var newName = ""
    @State private var renaming: StorageLocation?
    @State private var renameText = ""
    @State private var addingTo: StorageLocation?

    private let symbols = ["cabinet.fill", "shippingbox.fill", "backpack.fill", "car.fill", "cross.case.fill", "house.fill", "snowflake", "archivebox.fill", "building.2.fill", "tent.fill"]

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("New location", text: $newName).onSubmit(add)
                    Button("Add", action: add).disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            Section {
                ForEach(locations, id: \.uuid) { loc in
                    HStack {
                        Menu {
                            ForEach(symbols, id: \.self) { s in
                                Button { loc.symbol = s; try? context.save() } label: { Label(s, systemImage: s) }
                            }
                        } label: {
                            Image(systemName: loc.symbol).frame(width: 28)
                        }
                        Text(loc.name)
                        Spacer()
                        Text("\(loc.items.count)").foregroundStyle(.secondary)
                        Button { addingTo = loc } label: { Image(systemName: "plus.circle") }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Add a supply to \(loc.name)")
                    }
                    .swipeActions {
                        Button(role: .destructive) { context.delete(loc); try? context.save() } label: { Label("Delete", systemImage: "trash") }
                        Button { renaming = loc; renameText = loc.name } label: { Label("Rename", systemImage: "pencil") }
                        Button { addingTo = loc } label: { Label("Add supply", systemImage: "plus") }.tint(Color.ink)
                    }
                }
                .onMove { from, to in
                    var list = locations
                    list.move(fromOffsets: from, toOffset: to)
                    for (i, l) in list.enumerated() { l.sortOrder = i }
                    try? context.save()
                }
            } footer: {
                Text("Tap + to add a supply straight into a location. Deleting a location keeps its items; they just lose the label.")
            }
        }
        .sheet(item: $addingTo) { loc in ItemEditView(draft: ItemDraft(location: loc)) }
        .navigationTitle("Locations")
        .toolbar { EditButton() }
        .alert("Rename", isPresented: Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })) {
            TextField("Name", text: $renameText)
            Button("Save") {
                renaming?.name = renameText.trimmingCharacters(in: .whitespaces)
                try? context.save()
                renaming = nil
            }
            Button("Cancel", role: .cancel) { renaming = nil }
        }
    }

    private func add() {
        let n = newName.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty else { return }
        context.insert(StorageLocation(name: n, sortOrder: locations.count))
        newName = ""
        try? context.save()
    }
}
