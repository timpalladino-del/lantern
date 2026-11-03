import SwiftUI
import SwiftData

struct ContactsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \EmergencyContact.sortOrder) private var contacts: [EmergencyContact]
    @State private var editing: EmergencyContact?
    @State private var showNew = false
    @State private var shareFile: ShareableFile?

    private var builtIn: [EmergencyContact] { contacts.filter(\.isBuiltIn) }
    private var mine: [EmergencyContact] { contacts.filter { !$0.isBuiltIn } }

    var body: some View {
        List {
            Section {
                ForEach(builtIn, id: \.uuid) { c in ContactRow(contact: c) { editing = c } }
            } header: { Text("National") } footer: {
                Text("Tap a number to call. These work from any phone with service.")
            }

            Section {
                ForEach(mine, id: \.uuid) { c in
                    ContactRow(contact: c) { editing = c }
                        .swipeActions { Button(role: .destructive) { context.delete(c); try? context.save() } label: { Label("Delete", systemImage: "trash") } }
                }
                Button { showNew = true } label: { Label("Add a contact", systemImage: "plus") }
            } header: { Text("Mine") } footer: {
                Text("Add your power company's outage line, your county emergency management office, your vet, and the three people you'd call. Write them down here while you have signal.")
            }

            Section {
                Button { makePDF() } label: { Label("Print or save this list", systemImage: "printer") }
            } footer: {
                Text("A paper copy on the fridge works when the phone is dead.")
            }
        }
        .navigationTitle("Contacts")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editing) { c in ContactEditView(contact: c) }
        .sheet(isPresented: $showNew) { ContactEditView(contact: nil, nextOrder: contacts.count) }
        .sheet(item: $shareFile) { FileShareSheet(file: $0) }
    }

    private func makePDF() {
        let lines = contacts.map { c in "\(c.name)\(c.role.isEmpty ? "" : " (\(c.role))"): \(c.phone)\(c.notes.isEmpty ? "" : ". \(c.notes)")" }
        if let url = PrintService.makePDF(title: "Emergency contacts", subtitle: "Keep on the fridge and in the go-bag.",
                                          sections: [.init(heading: "Numbers", lines: lines)], filename: "lantern-contacts.pdf") {
            shareFile = ShareableFile(url: url)
        }
    }
}

struct ContactRow: View {
    let contact: EmergencyContact
    let onEdit: () -> Void

    private var telURL: URL? {
        let digits = contact.phone.filter { "0123456789+".contains($0) }
        return digits.isEmpty ? nil : URL(string: "tel://\(digits)")
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name).font(.subheadline.weight(.semibold))
                if !contact.role.isEmpty { Text(contact.role).font(.caption).foregroundStyle(.secondary) }
                if !contact.notes.isEmpty { Text(contact.notes).font(.caption).foregroundStyle(.secondary).lineLimit(2) }
            }
            Spacer()
            if let url = telURL {
                Link(destination: url) {
                    Text(contact.phone).font(.subheadline.weight(.semibold)).monospacedDigit()
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.12), in: Capsule())
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
    }
}

struct ContactEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    private let existing: EmergencyContact?
    private let nextOrder: Int
    @State private var name: String
    @State private var role: String
    @State private var phone: String
    @State private var notes: String

    init(contact: EmergencyContact?, nextOrder: Int = 0) {
        existing = contact
        self.nextOrder = nextOrder
        _name = State(initialValue: contact?.name ?? "")
        _role = State(initialValue: contact?.role ?? "")
        _phone = State(initialValue: contact?.phone ?? "")
        _notes = State(initialValue: contact?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Role (utility, neighbor, vet)", text: $role)
                TextField("Phone", text: $phone).keyboardType(.phonePad)
                TextField("Notes", text: $notes, axis: .vertical).lineLimit(2...5)
            }
            .navigationTitle(existing == nil ? "New contact" : "Edit contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let c = existing ?? EmergencyContact(name: name, sortOrder: nextOrder)
                        c.name = name.trimmingCharacters(in: .whitespaces); c.role = role; c.phone = phone; c.notes = notes
                        if existing == nil { context.insert(c) }
                        try? context.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
