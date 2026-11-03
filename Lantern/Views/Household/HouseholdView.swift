import SwiftUI
import SwiftData

/// The people and pets the app is covering. Used in onboarding, Settings, and the Ready tab.
struct HouseholdView: View {
    @Environment(\.modelContext) private var context
    @Bindable var household: Household
    var showTarget: Bool = true

    @State private var editingPerson: Person?
    @State private var showNewPerson = false
    @State private var editingPet: Pet?
    @State private var showNewPet = false

    private let targets = [3, 7, 14, 30]

    /// The first person is usually whoever set the app up; the request reads "Tim asked for your profile".
    private var requesterName: String { household.sortedPeople.first?.name ?? "Your household" }

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
                ShareLink(item: ProfileExchange.requestMessage(from: requesterName), subject: Text("Add yourself to our Lantern household")) {
                    Label("Ask someone to add themselves", systemImage: "paperplane")
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
