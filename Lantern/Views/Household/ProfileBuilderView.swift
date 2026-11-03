import SwiftUI
import SwiftData

/// Opened by a `lantern://profile/new` link on a family member's phone. They fill in their own profile
/// in a scratch store (so it never touches their own household), then send it back as a link.
struct ProfileBuilderView: View {
    let requestedBy: String
    @Environment(\.dismiss) private var dismiss
    @State private var scratch: ModelContainer? = try? AppSchema.container(inMemory: true)

    var body: some View {
        if let scratch {
            ProfileBuilderBody(requestedBy: requestedBy, onDone: { dismiss() })
                .modelContainer(scratch)
        } else {
            ContentUnavailableView("Couldn't start", systemImage: "exclamationmark.triangle", description: Text("Try again from the link."))
        }
    }
}

private struct ProfileBuilderBody: View {
    let requestedBy: String
    let onDone: () -> Void
    @Environment(\.modelContext) private var context
    @Query private var households: [Household]
    @Query private var people: [Person]
    @State private var showEditor = false
    @State private var editing: Person?

    private var requester: String { requestedBy.isEmpty ? "Someone" : requestedBy }
    private var household: Household {
        if let h = households.first { return h }
        let h = Household()
        context.insert(h)
        try? context.save()
        return h
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.plus").font(.largeTitle).foregroundStyle(Color.glow)
                            .symbolEffect(.bounce, options: .nonRepeating)
                        Text("\(requester) asked for your profile").font(.title3.weight(.semibold))
                        Text("Your age and size set how much food the household plans for. Medications and allergies go on the household's medication card so whoever is helping knows. Nothing leaves your phone until you tap Send.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                if let me = people.first {
                    Section("Your profile") {
                        Button { editing = me } label: { PersonRow(person: me) }.foregroundStyle(.primary)
                        ForEach(me.medications.sorted { $0.createdAt < $1.createdAt }, id: \.uuid) { m in
                            MedicationRow(medication: m)
                        }
                        Button { editing = me } label: { Label("Edit or add medications", systemImage: "pencil") }
                    }
                    Section {
                        if let text = ProfileExchange.replyMessage(for: ProfileCard(person: me, sentBy: me.name)) {
                            ShareLink(item: text, subject: Text("My Lantern profile")) {
                                Label("Send to \(requester)", systemImage: "paperplane.fill").font(.headline)
                            }
                        }
                    } footer: {
                        Text("Sends a link back by Messages, email or any app. \(requester) taps it and you appear in their household.")
                    }
                } else {
                    Section {
                        Button { showEditor = true } label: { Label("Start my profile", systemImage: "person.badge.plus").font(.headline) }
                    }
                }
            }
            .navigationTitle("Your profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { onDone() } } }
            .sheet(isPresented: $showEditor) { PersonEditView(household: household) }
            .sheet(item: $editing) { p in PersonEditView(household: household, person: p) }
        }
    }
}

/// Opened by a `lantern://profile/import` link on the owner's phone.
struct ProfileImportView: View {
    let card: ProfileCard
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var households: [Household]

    private var existingMatch: Person? {
        households.first?.people.first { $0.name.trimmingCharacters(in: .whitespaces).caseInsensitiveCompare(card.name.trimmingCharacters(in: .whitespaces)) == .orderedSame }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(card.name).font(.title2.weight(.semibold))
                        Text(card.summary).foregroundStyle(.secondary)
                        if !card.sentBy.isEmpty { Text("Sent by \(card.sentBy), \(card.createdAt.formatted(date: .abbreviated, time: .shortened))").font(.caption).foregroundStyle(.tertiary) }
                    }
                    .padding(.vertical, 4)
                }
                if !card.medications.isEmpty {
                    Section("Medications") {
                        ForEach(card.medications.indices, id: \.self) { i in
                            let m = card.medications[i]
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(m.name) \(m.dose)")
                                let times = m.scheduleMinutes.sorted().map { Medication.timeString(minutes: $0) }.joined(separator: ", ")
                                Text(times.isEmpty ? "\(Int(m.dosesPerDay)) a day" : times).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section {
                    Button { add() } label: {
                        Label(existingMatch == nil ? "Add \(card.name) to the household" : "Update \(card.name)'s profile", systemImage: "person.badge.plus").font(.headline)
                    }
                } footer: {
                    Text(existingMatch == nil
                         ? "Food and medication readiness update as soon as they are added."
                         : "There is already a \(card.name) here. Their details and medications will be replaced with what was sent.")
                }
            }
            .navigationTitle("Profile received")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Not now") { dismiss() } } }
        }
    }

    private func add() {
        let household = households.first ?? {
            let h = Household()
            context.insert(h)
            return h
        }()
        let person = existingMatch ?? {
            let p = Person(name: card.name)
            p.sortOrder = (household.people.map(\.sortOrder).max() ?? -1) + 1
            p.household = household
            context.insert(p)
            return p
        }()
        card.apply(to: person, in: context)
        try? context.save()
        dismiss()
    }
}
