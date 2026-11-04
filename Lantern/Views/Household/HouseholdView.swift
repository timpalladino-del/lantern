import SwiftUI
import SwiftData

/// The people and pets the app is covering. Used in onboarding, Settings, and the Ready tab.
struct HouseholdView: View {
    @Environment(\.modelContext) private var context
    @Bindable var household: Household
    var showTarget: Bool = true
    @Query private var plans: [HouseholdPlan]

    @State private var editingPerson: Person?
    @State private var showNewPerson = false
    @State private var editingPet: Pet?
    @State private var showNewPet = false
    @State private var showInvite = false

    private let targets = [3, 7, 14, 30]

    private var requesterName: String { household.admin?.name ?? "Your household" }

    var body: some View {
        List {
            Section {
                ForEach(household.sortedPeople, id: \.uuid) { person in
                    Button { editingPerson = person } label: { PersonRow(person: person) }
                        .foregroundStyle(.primary)
                        .swipeActions {
                            Button(role: .destructive) { context.delete(person); try? context.save() } label: { Label("Delete", systemImage: "trash") }
                        }
                }
                Button { showNewPerson = true } label: { Label("Add a person", systemImage: "person.badge.plus") }
                if PlanStore.shared.covers(peopleCount: household.people.count + 1) || household.people.contains(where: { $0.medications.isEmpty && $0.age == nil }) {
                    Button { showInvite = true } label: { Label("Invite someone to fill in their profile", systemImage: "paperplane") }
                } else {
                    LockedRow(title: "Ask someone to add themselves", reason: .secondPerson(coveredDays: nil))
                }
            } header: { Text("People") } footer: {
                if household.hasPeople {
                    Text("Together: about \(Int(household.caloriesPerDay.rounded())) calories a day.")
                } else {
                    Text("Add everyone who lives here, including yourself. Each person's age and size set the food target. Or send a link and let them fill in their own.")
                }
            }

            Section {
                ForEach(household.petList.sorted { $0.createdAt < $1.createdAt }, id: \.uuid) { pet in
                    Button { editingPet = pet } label: {
                        HStack {
                            Image(systemName: "pawprint.fill").foregroundStyle(.secondary).frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(pet.name)
                                Text("\(pet.species.title)\(pet.weightKg.map { String(format: " · %.0f lb", $0 * 2.20462) } ?? "")").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                    .swipeActions {
                        Button(role: .destructive) { context.delete(pet); try? context.save() } label: { Label("Delete", systemImage: "trash") }
                    }
                }
                Button { showNewPet = true } label: { Label("Add a pet", systemImage: "plus") }
            } header: { Text("Pets") }

            if household.people.count > 1 {
                Section {
                    Picker("Managed by", selection: Binding(get: { household.admin?.uuid ?? UUID() }, set: { household.adminPersonUUID = $0 })) {
                        ForEach(household.sortedPeople, id: \.uuid) { p in Text(p.name).tag(p.uuid) }
                    }
                } footer: {
                    Text("Invitations go out in this person's name and profiles come back to this phone.")
                }
            }

            if let plan = plans.first {
                TrustedContactSection(plan: plan, people: household.sortedPeople)
            }

            if showTarget {
                Section {
                    Picker("Days to cover", selection: $household.targetDays) {
                        ForEach(targets, id: \.self) { d in Text("\(d) days").tag(d) }
                    }
                } footer: {
                    Text("Red Cross: 3 days if you may need to leave, 2 weeks to stay home. Pick what feels right and work toward it.")
                }
            }
        }
        .sheet(item: $editingPerson) { p in PersonEditView(household: household, person: p) }
        .sheet(isPresented: $showNewPerson) { PersonEditView(household: household) }
        .sheet(item: $editingPet) { p in PetEditView(household: household, pet: p) }
        .sheet(isPresented: $showNewPet) { PetEditView(household: household) }
        .sheet(isPresented: $showInvite) { InviteSheet(household: household) }
    }
}

struct PersonRow: View {
    let person: Person
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: person.isChild ? "figure.child" : "person.fill").foregroundStyle(.secondary).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(person.name)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if person.isInfant {
                Text("Formula").font(.caption.weight(.medium)).foregroundStyle(.secondary)
            } else {
                Text("\(Int(person.dailyCalories.rounded())) kcal")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(person.caloriesAreEstimated ? .secondary : .primary)
            }
        }
    }
    private var subtitle: String {
        var parts: [String] = []
        if let a = person.age { parts.append(a == 1 ? "1 year" : "\(a) years") }
        if let w = person.weightKg { parts.append(String(format: "%.0f lb", w * 2.20462)) }
        if !person.medications.isEmpty { parts.append(person.medications.count == 1 ? "1 medication" : "\(person.medications.count) medications") }
        if parts.isEmpty { parts.append("Tap to add details") }
        return parts.joined(separator: " · ")
    }
}

/// Someone outside the house. They get the medication card and the plan, and the outage check-in names them.
struct TrustedContactSection: View {
    @Bindable var plan: HouseholdPlan
    let people: [Person]

    private var shareText: String {
        var s = MedicationCardView.cardText(for: people.filter { !$0.medications.isEmpty })
        if people.allSatisfy({ $0.medications.isEmpty }) { s = "MEDICATION CARD\n(no medications tracked yet)\n" }
        s += "\n\nOUR PLAN\n"
        if !plan.meetNearHome.isEmpty { s += "Meet near home: \(plan.meetNearHome)\n" }
        if !plan.meetOutsideNeighborhood.isEmpty { s += "Meet outside the neighborhood: \(plan.meetOutsideNeighborhood)\n" }
        if !plan.medicalNotes.isEmpty { s += "Medical: \(plan.medicalNotes)\n" }
        if !plan.documentsLocation.isEmpty { s += "Documents: \(plan.documentsLocation)\n" }
        s += "\nYou are listed as a trusted contact in Lantern. If you can't reach us during an emergency, this is what you need to know."
        return s
    }

    var body: some View {
        Section {
            TextField("Name (e.g. Dana, next door)", text: $plan.trustedContactName)
            TextField("Phone", text: $plan.trustedContactPhone).keyboardType(.phonePad)
            if !plan.trustedContactName.isEmpty || !plan.trustedContact2Name.isEmpty {
                TextField("Second contact (optional)", text: $plan.trustedContact2Name)
                TextField("Phone", text: $plan.trustedContact2Phone).keyboardType(.phonePad)
            }
            if plan.hasTrustedContact {
                ShareLink(item: shareText, subject: Text("Our medication card and plan")) {
                    Label("Send \(plan.trustedContacts.first!.name) the medication card and plan", systemImage: "square.and.arrow.up")
                }
            }
        } header: { Text("Who checks on you?") } footer: {
            Text(people.count <= 1
                 ? "Someone outside the house who knows your medications and your plan, and who you'll text during an outage. For a person living alone, this is the most important line in the app."
                 : "Someone outside the house who holds the medication card and the plan. The outage check-in reminder names them.")
        }
    }
}

/// Who the invitation is for (an existing person whose details are missing, or someone new) and the
/// message that goes out, with the steps written in.
struct InviteSheet: View {
    @Environment(\.dismiss) private var dismiss
    let household: Household
    @State private var target: String = ""      // uuid string of an existing person, or "" for new
    @State private var newName = ""

    private var requester: String { household.admin?.name ?? "Your household" }
    private var forName: String {
        if let p = household.people.first(where: { $0.uuid.uuidString == target }) { return p.name }
        return newName.trimmingCharacters(in: .whitespaces)
    }
    private var message: String { ProfileExchange.requestMessage(from: requester, forName: forName) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("This invitation is for", selection: $target) {
                        Text("Someone new").tag("")
                        ForEach(household.sortedPeople.filter { $0.uuid != household.admin?.uuid }, id: \.uuid) { p in
                            Text(p.name).tag(p.uuid.uuidString)
                        }
                    }
                    if target.isEmpty {
                        TextField("Their first name (optional)", text: $newName)
                    }
                } footer: {
                    Text(target.isEmpty
                         ? "A new person is added when their profile comes back."
                         : "Their reply updates \(forName)'s profile here instead of adding a second \(forName).")
                }
                Section("From") {
                    LabeledContent("Sent by", value: requester)
                }
                Section {
                    Text(message).font(.footnote).foregroundStyle(.secondary).textSelection(.enabled)
                } header: { Text("What they'll get") } footer: {
                    Text("Steps are in the message: get the app, open it once, tap their link, fill in, send back. The App Store link works once Lantern is live; TestFlight testers already have the app.")
                }
                Section {
                    ShareLink(item: message, subject: Text("Add yourself to our Lantern household")) {
                        Label("Send invitation", systemImage: "paperplane.fill").font(.headline)
                    }
                }
            }
            .navigationTitle("Invite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }
}
