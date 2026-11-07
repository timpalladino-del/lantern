import SwiftUI
import SwiftData

struct PlanView: View {
    @Environment(\.modelContext) private var context
    @Query private var plans: [HouseholdPlan]
    @Query(sort: \EmergencyContact.sortOrder) private var contacts: [EmergencyContact]
    @Query(sort: \Pet.createdAt) private var pets: [Pet]
    @State private var shareFile: ShareableFile?

    var body: some View {
        Group {
            if let plan = plans.first {
                PlanForm(plan: plan, onPrint: { makePDF(plan) })
            } else {
                ProgressView().task { SeedData.ensureDefaults(in: context) }
            }
        }
        .navigationTitle("Our plan")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $shareFile) { FileShareSheet(file: $0, title: "Put one on the fridge, one in each go-bag.") }
    }

    private func makePDF(_ p: HouseholdPlan) {
        let sections: [PrintService.Section] = [
            .init(heading: "Where we meet", lines: [
                "Near home: \(p.meetNearHome)" + (p.meetNearHomePoint.map { " (\($0.text), \($0.dms))" } ?? ""),
                "Outside the neighborhood: \(p.meetOutsideNeighborhood)" + (p.meetOutsidePoint.map { " (\($0.text), \($0.dms))" } ?? ""),
                "Out-of-town contact: \(p.outOfTownContact)"]),
            .init(heading: "People and pets", lines: ["Kids: \(p.kidsPlan)", "Pets: \(p.petsPlan)"] + pets.map(\.planLine) + ["Medical: \(p.medicalNotes)", "Documents: \(p.documentsLocation)"]),
            .init(heading: "Shutoffs", lines: ["Gas: \(p.gasShutoffNote)", "Water: \(p.waterShutoffNote)", "Electrical panel: \(p.electricPanelNote)"]),
            .init(heading: "Weather radio", lines: [p.noaaStation.isEmpty ? "" : "Station: \(p.noaaStation)"]),
            .init(heading: "Who checks on us", lines: p.trustedContacts.map { "\($0.name): \($0.phone)" }),
            .init(heading: "Contacts", lines: contacts.map { "\($0.name): \($0.phone)" })
        ]
        if let url = PrintService.makePDF(title: "Our emergency plan", subtitle: "Reviewed \(p.lastReviewedAt?.formatted(date: .long, time: .omitted) ?? "never")",
                                          sections: sections, filename: "lantern-plan.pdf") {
            shareFile = ShareableFile(url: url)
        }
    }
}

private struct PlanForm: View {
    @Environment(\.modelContext) private var context
    @Bindable var plan: HouseholdPlan
    let onPrint: () -> Void

    var body: some View {
        Form {
            Section {
                TextField("Near home (the big tree, the mailbox)", text: $plan.meetNearHome, axis: .vertical)
                TextField("Outside the neighborhood (library lot, a friend's)", text: $plan.meetOutsideNeighborhood, axis: .vertical)
                TextField("Out-of-town contact everyone checks in with", text: $plan.outOfTownContact, axis: .vertical)
            } header: { Text("Where we meet") } footer: {
                Text("Local calls fail first in a disaster. A relative in another state can relay messages for the whole family.")
            }
            CoordinateSection(title: "Near-home spot on the map", latitude: $plan.meetNearHomeLatitude, longitude: $plan.meetNearHomeLongitude) { try? context.save() }
            CoordinateSection(title: "Outside-the-neighborhood spot on the map", latitude: $plan.meetOutsideLatitude, longitude: $plan.meetOutsideLongitude) { try? context.save() }

            Section("People and pets") {
                TextField("Kids: who picks up, from where", text: $plan.kidsPlan, axis: .vertical)
                TextField("Pets: carriers, leashes, who grabs them", text: $plan.petsPlan, axis: .vertical)
                TextField("Medical: insulin in the fridge door, inhaler in the car", text: $plan.medicalNotes, axis: .vertical)
                TextField("Documents: where the box is, where the key is", text: $plan.documentsLocation, axis: .vertical)
            }

            Section {
                ShutoffRow(title: "Gas", note: $plan.gasShutoffNote, photo: $plan.gasShutoffPhoto, hint: "Quarter turn with a wrench. Only if you smell gas. Leave it off.")
                ShutoffRow(title: "Water", note: $plan.waterShutoffNote, photo: $plan.waterShutoffPhoto, hint: "Clockwise until it stops. Open a low faucet to drain.")
                ShutoffRow(title: "Electrical panel", note: $plan.electricPanelNote, photo: $plan.electricPanelPhoto, hint: "Main breaker at the top. Off before flood water reaches outlets.")
            } header: { Text("Shutoffs") } footer: {
                Text("Take the photos now, in daylight. You will be looking for these with a flashlight.")
            }

            Section {
                HStack {
                    Text("Last reviewed")
                    Spacer()
                    Text(plan.lastReviewedAt?.formatted(date: .abbreviated, time: .omitted) ?? "Never").foregroundStyle(.secondary)
                }
                Button("We reviewed it today") { plan.lastReviewedAt = Date(); try? context.save() }
                Button { onPrint() } label: { Label("Print or save the plan", systemImage: "printer") }
            } footer: {
                Text("Review twice a year. The clock changes are a good reminder.")
            }
        }
        .onChange(of: plan.meetNearHome) { _, _ in try? context.save() }
        .onChange(of: plan.meetOutsideNeighborhood) { _, _ in try? context.save() }
        .onChange(of: plan.outOfTownContact) { _, _ in try? context.save() }
        .onChange(of: plan.kidsPlan) { _, _ in try? context.save() }
        .onChange(of: plan.petsPlan) { _, _ in try? context.save() }
        .onChange(of: plan.medicalNotes) { _, _ in try? context.save() }
        .onChange(of: plan.documentsLocation) { _, _ in try? context.save() }
    }
}

private struct ShutoffRow: View {
    @Environment(\.modelContext) private var context
    let title: String
    @Binding var note: String
    @Binding var photo: Data?
    let hint: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.semibold))
            TextField("Where it is and which way to turn", text: $note, axis: .vertical)
                .onChange(of: note) { _, _ in try? context.save() }
            PhotoPickerButton(photoData: $photo)
                .onChange(of: photo) { _, _ in try? context.save() }
            Text(hint).font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
