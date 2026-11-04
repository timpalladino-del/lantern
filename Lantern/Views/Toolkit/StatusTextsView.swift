import SwiftUI
import SwiftData
import UIKit

/// Pre-written messages for the moment the phone is at 9 percent and everyone is asking.
/// Texts get through when calls do not. Filled in from the household, the outage clock and the plan.
struct StatusTextsView: View {
    @Query private var households: [Household]
    @Query(sort: \OutageEvent.startedAt, order: .reverse) private var outages: [OutageEvent]
    @Query private var plans: [HouseholdPlan]
    @Query(sort: \EmergencyContact.sortOrder) private var contacts: [EmergencyContact]
    @State private var copied: String?

    private var household: Household? { households.first }
    private var outage: OutageEvent? { outages.first { $0.isActive } }
    private var plan: HouseholdPlan? { plans.first }
    private var mine: [EmergencyContact] { contacts.filter { !$0.isBuiltIn && !$0.phone.isEmpty } }

    struct Message: Identifiable { let id: String; let title: String; let symbol: String; let body: String }

    var messages: [Message] { StatusTextsView.messages(household: household, outage: outage, plan: plan, now: Date()) }

    var body: some View {
        List {
            Section {
                ForEach(messages) { m in
                    VStack(alignment: .leading, spacing: 8) {
                        Label(m.title, systemImage: m.symbol).font(.headline)
                        Text(m.body).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 10) {
                            Button {
                                open(sms: nil, body: m.body)
                            } label: { Label("Text", systemImage: "message.fill") }
                                .buttonStyle(.borderedProminent)
                            ShareLink(item: m.body) { Label("Share", systemImage: "square.and.arrow.up") }
                                .buttonStyle(.bordered)
                            Button {
                                UIPasteboard.general.string = m.body; copied = m.id
                            } label: { Label(copied == m.id ? "Copied" : "Copy", systemImage: copied == m.id ? "checkmark" : "doc.on.doc") }
                                .buttonStyle(.bordered)
                        }
                        .font(.subheadline)
                    }
                    .padding(.vertical, 4)
                }
            } header: { Text("Pick one, pick who, send") } footer: {
                Text("Text opens Messages with the words filled in; you choose who. Names, the outage clock and your meeting place come from Lantern, so the message is right without typing in the dark.")
            }

            if !mine.isEmpty {
                Section {
                    ForEach(mine, id: \.uuid) { c in
                        Menu {
                            ForEach(messages) { m in
                                Button(m.title) { open(sms: c.phone, body: m.body) }
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(c.name).foregroundStyle(.primary)
                                    if !c.role.isEmpty { Text(c.role).font(.caption).foregroundStyle(.secondary) }
                                }
                                Spacer()
                                Image(systemName: "message").foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                } header: { Text("Straight to your people") } footer: {
                    Text("From your contacts list. Tap a name, pick a message, Messages opens addressed to them.")
                }
            }

            Section {
                NavigationLink { ContactsView() } label: { Label("Edit the contacts list", systemImage: "phone.fill") }
                NavigationLink { OutageView() } label: { Label(outage == nil ? "Start the outage clock" : "Outage mode", systemImage: "powerplug") }
            } footer: {
                Text("When the phone is low: airplane mode between messages, screen dim, one text to a group instead of five calls.")
            }
        }
        .navigationTitle("Ready-to-send texts")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func open(sms number: String?, body: String) {
        let digits = (number ?? "").filter { "+0123456789".contains($0) }
        var parts = URLComponents()
        parts.scheme = "sms"
        parts.path = digits
        parts.queryItems = [URLQueryItem(name: "body", value: body)]
        // Messages wants "sms:NUMBER&body=" on iOS; URLComponents gives "sms:NUMBER?body=", which also works.
        if let url = parts.url, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            UIPasteboard.general.string = body
        }
    }

    /// Built as a static function so it can be tested without a view.
    static func messages(household: Household?, outage: OutageEvent?, plan: HouseholdPlan?, now: Date) -> [Message] {
        let people = household?.people.map(\.name).filter { !$0.isEmpty } ?? []
        let who: String = {
            switch people.count {
            case 0: return "We're"
            case 1: return "\(people[0]) is"
            case 2: return "\(people[0]) and \(people[1]) are"
            default: return "\(people.dropLast().joined(separator: ", ")) and \(people.last!) are"
            }
        }()
        let since = outage.map { " since \($0.startedAt.formatted(date: .omitted, time: .shortened))" } ?? ""
        let next = now.addingTimeInterval(4 * 3600).formatted(date: .omitted, time: .shortened)
        let meet = plan?.meetNearHome.trimmingCharacters(in: .whitespaces) ?? ""
        let meetFar = plan?.meetOutsideNeighborhood.trimmingCharacters(in: .whitespaces) ?? ""
        let outOfTown = plan?.outOfTownContact.trimmingCharacters(in: .whitespaces) ?? ""

        var list: [Message] = [
            Message(id: "safe", title: "We're safe", symbol: "checkmark.shield.fill",
                    body: "\(who) safe at home. Power's out\(since). Phones are low, so we're texting instead of calling. Next check-in around \(next)."),
            Message(id: "leaving", title: "We're leaving", symbol: "car.fill",
                    body: "\(who) leaving the house now. Everyone's accounted for.\(meetFar.isEmpty ? "" : " Heading to \(meetFar).") Will text when we get there."),
            Message(id: "arrived", title: "We made it", symbol: "house.fill",
                    body: "\(who) safe and settled.\(meetFar.isEmpty ? "" : " We're at \(meetFar).") Phones are low; one text every few hours."),
            Message(id: "help", title: "We need a hand", symbol: "hand.raised.fill",
                    body: "\(who) okay but could use help. Power's out\(since) and we're running short. Can you call or come by when you can?"),
            Message(id: "checkin", title: "Checking on you", symbol: "person.2.fill",
                    body: "Checking in. Are you okay? Power's out here\(since). Text back when you can, even one word."),
        ]
        if !meet.isEmpty {
            list.append(Message(id: "meet", title: "Meet at our spot", symbol: "mappin.and.ellipse",
                                body: "If we get separated, meet at \(meet)." + (meetFar.isEmpty ? "" : " If that's not safe, \(meetFar).") + (outOfTown.isEmpty ? "" : " Out-of-town check-in: \(outOfTown).")))
        }
        return list
    }
}
