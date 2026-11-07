import SwiftUI
import CoreLocation

/// Watches, warnings and advisories from the National Weather Service for the places the household saved.
struct WeatherAlertsView: View {
    @State private var store = WeatherAlertStore.shared
    @State private var showAdd = false
    @State private var now = Date()

    var body: some View {
        List {
            if store.hasPlaces {
                statusSection
                alertsSection
            } else {
                introSection
            }
            placesSection
            if store.hasPlaces { notificationSection }
        }
        .navigationTitle("Weather alerts")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAdd) { AddAlertPlaceView().tint(Color.ink) }
        .task {
            now = Date()
            if store.isStale(now: now) { await store.refresh(notify: false, now: now) }
        }
        .refreshable { await store.refresh(notify: false) }
    }

    private var introSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Label("Save the places you care about", systemImage: "mappin.and.ellipse")
                    .font(.headline)
                Text("Home, a parent's house, the school. Lantern checks the National Weather Service for each one when you open the app and now and then in the background, and tells you about new watches and warnings.")
                    .font(.subheadline).foregroundStyle(.secondary)
                Text("Wireless Emergency Alerts and a weather radio are still the fastest warning. This is the layer that covers places you are not standing in.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    private var statusSection: some View {
        Section {
            HStack {
                if store.isChecking {
                    ProgressView().controlSize(.small)
                    Text("Checking weather.gov").foregroundStyle(.secondary)
                } else {
                    Image(systemName: "checkmark.circle").foregroundStyle(Color.moss)
                    Text(store.lastChecked.map { "Checked \($0.formatted(.relative(presentation: .named)))" } ?? "Not checked yet")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Check now") { Task { await store.refresh(notify: false) } }
                    .disabled(store.isChecking)
            }
            if let e = store.lastError {
                Label(e, systemImage: "wifi.exclamationmark").font(.footnote).foregroundStyle(Color.ember)
            }
        }
    }

    @ViewBuilder
    private var alertsSection: some View {
        let active = store.activeAlerts(now: now)
        Section {
            if active.isEmpty {
                Label("Nothing in effect for your places.", systemImage: "sun.max")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(active) { a in
                    NavigationLink { WeatherAlertDetailView(alert: a) } label: { WeatherAlertRow(alert: a, now: now) }
                }
            }
        } header: { Text("In effect") } footer: {
            Text(NWSClient.attribution)
        }
    }

    private var placesSection: some View {
        Section {
            ForEach(store.places) { p in
                HStack {
                    Image(systemName: "mappin.circle.fill").foregroundStyle(Color.ink)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(p.name)
                        Text(p.zip.isEmpty ? p.point.text : "ZIP \(p.zip)").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    let n = store.alerts(for: p, now: now).count
                    if n > 0 {
                        Text(n == 1 ? "1 alert" : "\(n) alerts").font(.caption.weight(.semibold))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.ember.opacity(0.15), in: Capsule())
                            .foregroundStyle(Color.ember)
                    }
                }
                .swipeActions {
                    Button(role: .destructive) { store.remove(p) } label: { Label("Remove", systemImage: "trash") }
                }
            }
            Button { showAdd = true } label: { Label("Add a place", systemImage: "plus") }
        } header: { Text("Places") } footer: {
            if store.hasPlaces {
                Text("Only the coordinates of these places are sent to weather.gov. United States only.")
            }
        }
    }

    private var notificationSection: some View {
        Section {
            Toggle("Tell me about new alerts", isOn: Binding(get: { store.notificationsEnabled }, set: { store.notificationsEnabled = $0 }))
            Picker("At least", selection: Binding(get: { store.minimumSeverity }, set: { store.minimumSeverity = $0 })) {
                Text("Any advisory").tag(WeatherAlert.Severity.unknown)
                Text("Moderate").tag(WeatherAlert.Severity.moderate)
                Text("Severe").tag(WeatherAlert.Severity.severe)
                Text("Extreme only").tag(WeatherAlert.Severity.extreme)
            }
        } header: { Text("Notifications") } footer: {
            Text("One notification per new alert, none repeated. iOS decides how often the background check runs, usually a few times a day, so keep Wireless Emergency Alerts on for the fastest warning.")
        }
    }
}

struct WeatherAlertRow: View {
    let alert: WeatherAlert
    var now: Date = Date()

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: alert.isWarning ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(alert.isWarning ? Color.ember : Color.ink)
                .font(.title3)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(alert.event).font(.body.weight(.semibold))
                Text([alert.placeNames.joined(separator: ", "), alert.untilText(now: now)].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.subheadline).foregroundStyle(.secondary)
                if !alert.instruction.isEmpty {
                    Text(alert.instruction).font(.footnote).foregroundStyle(.secondary).lineLimit(2)
                }
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}

struct WeatherAlertDetailView: View {
    let alert: WeatherAlert

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(alert.headline.isEmpty ? alert.event : alert.headline).font(.headline)
                    HStack(spacing: 8) {
                        Chip(text: alert.severity.title, tint: alert.isWarning ? Color.ember : Color.ink)
                        if !alert.urgency.isEmpty { Chip(text: alert.urgency, tint: .secondary) }
                        if !alert.certainty.isEmpty { Chip(text: alert.certainty, tint: .secondary) }
                    }
                    if let until = alert.untilText() { Text(until).font(.subheadline).foregroundStyle(.secondary) }
                }
                .padding(.vertical, 4)
            }
            if !alert.instruction.isEmpty {
                Section("What to do") {
                    Text(alert.instruction).font(.body.weight(.medium))
                }
            }
            if !alert.description.isEmpty {
                Section("Details") {
                    Text(alert.description).font(.callout)
                }
            }
            Section {
                if !alert.placeNames.isEmpty { LabeledContent("Your places", value: alert.placeNames.joined(separator: ", ")) }
                if !alert.areaDesc.isEmpty { LabeledContent("Area", value: alert.areaDesc) }
                if let onset = alert.onset { LabeledContent("Starts", value: onset.formatted(date: .abbreviated, time: .shortened)) }
                if let end = alert.endsAt { LabeledContent("Ends", value: end.formatted(date: .abbreviated, time: .shortened)) }
                LabeledContent("Issued by", value: alert.senderName)
            } footer: { Text(NWSClient.attribution) }
        }
        .navigationTitle(alert.event)
        .navigationBarTitleDisplayMode(.inline)
    }

    private struct Chip: View {
        let text: String
        let tint: Color
        var body: some View {
            Text(text).font(.caption.weight(.semibold))
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(tint.opacity(0.15), in: Capsule())
                .foregroundStyle(tint)
        }
    }
}

/// Name a place and give a ZIP code, or stand there and tap the button.
struct AddAlertPlaceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store = WeatherAlertStore.shared
    @State private var name = ""
    @State private var zip = ""
    @State private var fix = LocationFix()
    @State private var located: GeoPoint?
    @State private var locatedName: String?
    @State private var working = false
    @State private var error: String?

    private var canSave: Bool { !working && (AlertPlace.isValidZIP(zip) || located != nil) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name (Home, Mom's house, school)", text: $name)
                    TextField("ZIP code", text: $zip).keyboardType(.numberPad).textContentType(.postalCode)
                } footer: {
                    Text("A ZIP code is turned into a coordinate once, on this phone.")
                }
                Section {
                    Button {
                        fix.request { loc in
                            located = GeoPoint(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
                            Task { locatedName = await WeatherAlertStore.placeName(for: loc) }
                        }
                    } label: {
                        HStack {
                            Label("Use my location", systemImage: "location.fill")
                            Spacer()
                            if fix.isWorking { ProgressView().controlSize(.small) }
                        }
                    }
                    .disabled(fix.isWorking)
                    if let p = located {
                        LabeledContent("Here", value: [locatedName, p.text].compactMap { $0 }.joined(separator: " · "))
                    }
                    if fix.denied {
                        Text("Location is off for Lantern in iOS Settings. A ZIP code works just as well.").font(.footnote).foregroundStyle(Color.ember)
                    }
                } footer: {
                    Text("Either one works. Use your location for where you are now, a ZIP code for anywhere else.")
                }
            }
            .navigationTitle("Add a place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if working { ProgressView() } else { Button("Save") { Task { await save() } }.disabled(!canSave) }
                }
            }
            .alert("Could not find that place", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK", role: .cancel) { error = nil }
            } message: { Text(error ?? "") }
        }
    }

    private func save() async {
        working = true
        defer { working = false }
        let trimmedZip = zip.trimmingCharacters(in: .whitespaces)
        do {
            let place: AlertPlace
            if AlertPlace.isValidZIP(trimmedZip) {
                let found = try await WeatherAlertStore.geocode(zip: trimmedZip)
                let label = name.trimmingCharacters(in: .whitespaces)
                place = AlertPlace(name: label.isEmpty ? found.name : label, zip: String(trimmedZip.prefix(5)), latitude: found.point.latitude, longitude: found.point.longitude)
            } else if let p = located {
                let label = name.trimmingCharacters(in: .whitespaces)
                place = AlertPlace(name: label.isEmpty ? (locatedName ?? "Here") : label, zip: "", latitude: p.latitude, longitude: p.longitude)
            } else { return }
            store.add(place)
            WeatherRefreshTask.schedule()
            dismiss()
            await store.refresh(notify: false)
        } catch {
            self.error = "Check the ZIP code. Lantern looks up United States ZIP codes only, and needs a connection to do it."
        }
    }
}
