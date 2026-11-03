import SwiftUI
import SwiftData

/// The one page an ER nurse, a neighbour or a shelter volunteer needs: who takes what, when, how, and
/// what to avoid. Share as text to the family group chat, or print for the fridge and the go-bag.
struct MedicationCardView: View {
    @Query private var households: [Household]
    @State private var shareFile: ShareableFile?

    private var people: [Person] { households.first?.sortedPeople ?? [] }
    private var coveredPeople: [Person] { Array(people.prefix(PlanStore.shared.plan.maxPeople)) }
    private var peopleWithMeds: [Person] { coveredPeople.filter { !$0.medications.isEmpty } }
    private var uncoveredCount: Int { people.count - coveredPeople.count }

    var body: some View {
        List {
            if peopleWithMeds.isEmpty {
                ContentUnavailableView {
                    Label("No medications yet", systemImage: "pills")
                } description: {
                    Text("Add medications to each person under Household and this card fills itself in.")
                }
            } else {
                ForEach(peopleWithMeds, id: \.uuid) { person in
                    Section {
                        ForEach(person.medications.sorted { $0.createdAt < $1.createdAt }, id: \.uuid) { m in
                            MedicationCardRow(medication: m)
                        }
                        if !person.allergies.isEmpty {
                            Label("Allergies: \(person.allergies)", systemImage: "allergens")
                                .font(.footnote).foregroundStyle(Color.ember)
                        }
                    } header: {
                        Text(person.name)
                    }
                }
                if uncoveredCount > 0 {
                    Section {
                        LockedRow(title: uncoveredCount == 1 ? "1 more person is part of Family" : "\(uncoveredCount) more people are part of Family", reason: .feature("Everyone's medication card"))
                    }
                }
                Section {
                    ShareLink(item: MedicationCardView.cardText(for: peopleWithMeds), subject: Text("Medication card"),
                              message: Text("Our household medication card from Lantern.")) {
                        Label("Share as text", systemImage: "square.and.arrow.up")
                    }
                    Button { makePDF() } label: { Label("Print or save PDF", systemImage: "printer") }
                } footer: {
                    Text("Text goes anywhere: a family group chat, a caregiver, a shelter intake desk. The PDF is for the fridge and the go-bag. Everything stays on this phone until you share it.")
                }
            }
        }
        .navigationTitle("Medication card")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $shareFile) { FileShareSheet(file: $0) }
    }

    private func makePDF() {
        let sections: [PrintService.Section] = peopleWithMeds.map { person in
            var lines: [String] = []
            for m in person.medications.sorted(by: { $0.createdAt < $1.createdAt }) {
                lines.append(contentsOf: MedicationCardView.lines(for: m, indent: "   "))
                lines.append("")
            }
            if !person.allergies.isEmpty { lines.append("ALLERGIES: \(person.allergies)") }
            if !person.dietaryNotes.isEmpty { lines.append("Diet: \(person.dietaryNotes)") }
            return .init(heading: person.name, lines: lines)
        }
        if let url = PrintService.makePDF(title: "Medication card", subtitle: "Who takes what, when, and how. Hand this to whoever is helping.",
                                          sections: sections, filename: "lantern-medications.pdf") {
            shareFile = ShareableFile(url: url)
        }
    }

    static func lines(for m: Medication, indent: String = "") -> [String] {
        var out: [String] = []
        var head = m.name
        if !m.dose.isEmpty { head += " \(m.dose)" }
        head += " (\(m.form.title.lowercased()))"
        if m.isCritical { head += " — CANNOT MISS A DAY" }
        out.append(head)
        if !m.purpose.isEmpty { out.append("\(indent)For: \(m.purpose)") }
        let units = m.unitsPerDose == m.unitsPerDose.rounded() ? String(Int(m.unitsPerDose)) : String(format: "%.1f", m.unitsPerDose)
        out.append("\(indent)Take: \(units) \(m.unitsPerDose == 1 ? String(m.form.unitName.dropLast()) : m.form.unitName), \(m.scheduleMinutes.isEmpty ? m.scheduleSummary.lowercased() : "at " + m.scheduleSummary)")
        let howTo = m.instructions.filter { $0.kind == .howToTake }.map(\.title)
        let warnings = m.instructions.filter { $0.kind == .warning }.map(\.title)
        if !howTo.isEmpty { out.append("\(indent)How: \(howTo.joined(separator: "; "))") }
        if !warnings.isEmpty { out.append("\(indent)Avoid: \(warnings.joined(separator: "; "))") }
        if !m.customInstructions.isEmpty { out.append("\(indent)Also: \(m.customInstructions)") }
        if let d = m.daysOfSupply { out.append("\(indent)Supply: about \(ReadinessCalculator.formatDays(d)) on hand") }
        if let e = m.expirationDate { out.append("\(indent)Expires: \(e.formatted(date: .abbreviated, time: .omitted))") }
        var who: [String] = []
        if !m.prescriber.isEmpty { who.append("Prescriber: \(m.prescriber)\(m.prescriberPhone.isEmpty ? "" : " \(m.prescriberPhone)")") }
        if !m.pharmacy.isEmpty { who.append("Pharmacy: \(m.pharmacy)\(m.pharmacyPhone.isEmpty ? "" : " \(m.pharmacyPhone)")") }
        if !m.rxNumber.isEmpty { who.append("Rx #\(m.rxNumber)") }
        if !who.isEmpty { out.append("\(indent)\(who.joined(separator: " · "))") }
        if !m.notes.isEmpty { out.append("\(indent)Notes: \(m.notes)") }
        return out
    }

    static func cardText(for people: [Person]) -> String {
        var s = "MEDICATION CARD\n"
        for p in people {
            s += "\n\(p.name.uppercased())\n"
            for m in p.medications.sorted(by: { $0.createdAt < $1.createdAt }) {
                let ls = lines(for: m)
                s += "• " + ls[0] + "\n"
                for l in ls.dropFirst() { s += "   " + l + "\n" }
            }
            if !p.allergies.isEmpty { s += "ALLERGIES: \(p.allergies)\n" }
        }
        s += "\nFrom Lantern, \(Date().formatted(date: .abbreviated, time: .omitted))."
        return s
    }
}

struct MedicationCardRow: View {
    let medication: Medication

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(medication.name).font(.headline)
                if !medication.dose.isEmpty { Text(medication.dose).foregroundStyle(.secondary) }
                if medication.isCritical {
                    Image(systemName: "exclamationmark.circle.fill").foregroundStyle(Color.ember).font(.caption)
                        .accessibilityLabel("Cannot miss a day")
                }
                Spacer()
                if let d = medication.daysOfSupply {
                    Text(ReadinessCalculator.formatDays(d)).font(.caption.weight(.medium)).foregroundStyle(d < 7 ? Color.ember : Color.secondary)
                }
            }
            if !medication.purpose.isEmpty { Text("For \(medication.purpose)").font(.subheadline).foregroundStyle(.secondary) }
            Label(medication.scheduleSummary, systemImage: "clock").font(.subheadline)
            ForEach(medication.instructions) { ins in
                Label(ins.title, systemImage: ins.symbol)
                    .font(.footnote)
                    .foregroundStyle(ins.kind == .warning ? Color.ember : Color.secondary)
            }
            if !medication.customInstructions.isEmpty {
                Label(medication.customInstructions, systemImage: "text.quote").font(.footnote).foregroundStyle(.secondary)
            }
            if !medication.pharmacy.isEmpty || !medication.prescriber.isEmpty {
                Text([medication.prescriber, medication.pharmacy].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.caption).foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
