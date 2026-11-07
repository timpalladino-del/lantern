import Foundation
import CoreLocation
import BackgroundTasks
import UserNotifications
import Observation

// MARK: - Places

/// A spot the household cares about: home, Grandma's, the lake house. Saved by ZIP code or from the phone's
/// location, kept as coordinates only. Nothing but the coordinates ever leaves the phone.
struct AlertPlace: Codable, Identifiable, Equatable, Hashable {
    var id: UUID = UUID()
    var name: String
    var zip: String = ""
    var latitude: Double
    var longitude: Double

    var point: GeoPoint { GeoPoint(latitude: latitude, longitude: longitude) }

    /// US ZIP codes are five digits, optionally with a four-digit suffix.
    static func isValidZIP(_ raw: String) -> Bool {
        let s = raw.trimmingCharacters(in: .whitespaces)
        let parts = s.split(separator: "-", omittingEmptySubsequences: false)
        guard let first = parts.first, first.count == 5, first.allSatisfy(\.isNumber) else { return false }
        if parts.count == 1 { return true }
        return parts.count == 2 && parts[1].count == 4 && parts[1].allSatisfy(\.isNumber)
    }
}

// MARK: - Alerts

/// One National Weather Service alert, trimmed to what a household needs to read in a hurry.
struct WeatherAlert: Codable, Identifiable, Equatable, Hashable {
    enum Severity: Int, Codable, Comparable, CaseIterable {
        case unknown = 0, minor, moderate, severe, extreme

        init(label: String) {
            switch label.lowercased() {
            case "minor": self = .minor
            case "moderate": self = .moderate
            case "severe": self = .severe
            case "extreme": self = .extreme
            default: self = .unknown
            }
        }

        var title: String {
            switch self {
            case .unknown: return "Unknown"
            case .minor: return "Minor"
            case .moderate: return "Moderate"
            case .severe: return "Severe"
            case .extreme: return "Extreme"
            }
        }

        static func < (a: Severity, b: Severity) -> Bool { a.rawValue < b.rawValue }
    }

    let id: String
    let event: String
    let severity: Severity
    let urgency: String
    let certainty: String
    let headline: String
    let description: String
    let instruction: String
    let onset: Date?
    let ends: Date?
    let expires: Date?
    let areaDesc: String
    let senderName: String
    let messageType: String
    /// Names of the saved places this alert covers. Filled in by the store, not the feed.
    var placeNames: [String] = []

    /// NWS gives `ends` for the hazard and `expires` for the message. Whichever is later keeps it on screen.
    var endsAt: Date? {
        switch (ends, expires) {
        case let (e?, x?): return max(e, x)
        case let (e?, nil): return e
        case let (nil, x?): return x
        default: return nil
        }
    }

    func isActive(at now: Date) -> Bool {
        guard let end = endsAt else { return true }
        return end > now
    }

    /// "Watch" means be ready; "Warning" means it is happening or about to. Used for the banner tint.
    var isWarning: Bool { event.localizedCaseInsensitiveContains("warning") || severity == .extreme }

    /// "Until 9:15 PM" or "Until Sat 8:00 PM" for anything past today.
    func untilText(now: Date = Date()) -> String? {
        guard let end = endsAt else { return nil }
        let sameDay = Calendar.current.isDate(end, inSameDayAs: now)
        return "Until " + (sameDay ? end.formatted(date: .omitted, time: .shortened) : end.formatted(.dateTime.weekday(.abbreviated).hour().minute()))
    }
}

/// Talks to api.weather.gov. Public, no key, United States only. The only thing sent is a coordinate pair.
enum NWSClient {
    static let attribution = "Alerts from the National Weather Service (weather.gov)."
    static let userAgent = "Lantern/1.0 (iOS; features@castlewise.app)"

    static func url(for point: GeoPoint) -> URL {
        URL(string: String(format: "https://api.weather.gov/alerts/active?status=actual&point=%.4f,%.4f", point.latitude, point.longitude))!
    }

    static func activeAlerts(at point: GeoPoint, session: URLSession = .shared) async throws -> [WeatherAlert] {
        var request = URLRequest(url: url(for: point))
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/geo+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 20
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        return try parse(data)
    }

    private struct Feed: Decodable {
        struct Feature: Decodable {
            struct Properties: Decodable {
                let id: String
                let event: String?
                let severity: String?
                let urgency: String?
                let certainty: String?
                let headline: String?
                let description: String?
                let instruction: String?
                let onset: String?
                let ends: String?
                let expires: String?
                let areaDesc: String?
                let senderName: String?
                let messageType: String?
                let status: String?
            }
            let properties: Properties
        }
        let features: [Feature]
    }

    nonisolated static func parse(_ data: Data) throws -> [WeatherAlert] {
        let feed = try JSONDecoder().decode(Feed.self, from: data)
        let iso = ISO8601DateFormatter()
        func date(_ s: String?) -> Date? { s.flatMap { iso.date(from: $0) } }
        return feed.features.compactMap { f -> WeatherAlert? in
            let p = f.properties
            // Tests and exercises are marked Test/Exercise/Draft; only real messages reach the household.
            if let status = p.status, status.lowercased() != "actual" { return nil }
            if p.messageType?.lowercased() == "cancel" { return nil }
            return WeatherAlert(
                id: p.id,
                event: p.event ?? "Weather alert",
                severity: WeatherAlert.Severity(label: p.severity ?? ""),
                urgency: p.urgency ?? "",
                certainty: p.certainty ?? "",
                headline: p.headline ?? p.event ?? "",
                description: (p.description ?? "").replacingOccurrences(of: "\n\n", with: "\u{2029}").replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "\u{2029}", with: "\n\n"),
                instruction: (p.instruction ?? "").replacingOccurrences(of: "\n", with: " "),
                onset: date(p.onset),
                ends: date(p.ends),
                expires: date(p.expires),
                areaDesc: p.areaDesc ?? "",
                senderName: p.senderName ?? "National Weather Service",
                messageType: p.messageType ?? "")
        }
    }
}

// MARK: - Store

/// Saved places, the latest alerts for them, and which ones the household has already been told about.
/// Lives in UserDefaults so the background task can run without opening the database.
@MainActor
@Observable
final class WeatherAlertStore {
    static let shared = WeatherAlertStore()

    enum Keys {
        static let places = "weather.places"
        static let alerts = "weather.alerts"
        static let seen = "weather.seen"
        static let lastChecked = "weather.lastChecked"
        static let minimumSeverity = "weather.minimumSeverity"
        static let notify = "weather.notify"
    }

    private(set) var places: [AlertPlace]
    private(set) var alerts: [WeatherAlert]
    private(set) var lastChecked: Date?
    private(set) var isChecking = false
    private(set) var lastError: String?
    var minimumSeverity: WeatherAlert.Severity {
        didSet { defaults.set(minimumSeverity.rawValue, forKey: Keys.minimumSeverity) }
    }
    var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Keys.notify) }
    }

    private let defaults: UserDefaults
    private var seen: Set<String>

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let decoder = JSONDecoder()
        places = defaults.data(forKey: Keys.places).flatMap { try? decoder.decode([AlertPlace].self, from: $0) } ?? []
        alerts = defaults.data(forKey: Keys.alerts).flatMap { try? decoder.decode([WeatherAlert].self, from: $0) } ?? []
        seen = Set(defaults.stringArray(forKey: Keys.seen) ?? [])
        lastChecked = defaults.object(forKey: Keys.lastChecked) as? Date
        minimumSeverity = WeatherAlert.Severity(rawValue: defaults.integer(forKey: Keys.minimumSeverity)) ?? .unknown
        if defaults.object(forKey: Keys.minimumSeverity) == nil { minimumSeverity = .severe }
        notificationsEnabled = defaults.object(forKey: Keys.notify) as? Bool ?? true
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-weatherdemo") { loadDemo() }
        #endif
    }

    var hasPlaces: Bool { !places.isEmpty }

    /// Alerts still in force, worst first.
    func activeAlerts(now: Date = Date()) -> [WeatherAlert] {
        alerts.filter { $0.isActive(at: now) }
            .sorted { a, b in a.severity != b.severity ? a.severity > b.severity : (a.endsAt ?? .distantFuture) < (b.endsAt ?? .distantFuture) }
    }

    func alerts(for place: AlertPlace, now: Date = Date()) -> [WeatherAlert] {
        activeAlerts(now: now).filter { $0.placeNames.contains(place.name) }
    }

    /// Fifteen minutes is often enough; the feed itself updates every few minutes.
    func isStale(now: Date = Date()) -> Bool {
        guard let last = lastChecked else { return true }
        return now.timeIntervalSince(last) > 15 * 60
    }

    // MARK: Places

    func add(_ place: AlertPlace) {
        guard !places.contains(where: { $0.name.caseInsensitiveCompare(place.name) == .orderedSame }) else { return }
        places.append(place)
        persistPlaces()
    }

    func remove(_ place: AlertPlace) {
        places.removeAll { $0.id == place.id }
        alerts = alerts.map { a in
            var a = a
            a.placeNames.removeAll { $0 == place.name }
            return a
        }.filter { !$0.placeNames.isEmpty }
        persistPlaces()
        persistAlerts()
    }

    func rename(_ place: AlertPlace, to name: String) {
        guard let i = places.firstIndex(where: { $0.id == place.id }) else { return }
        let old = places[i].name
        places[i].name = name
        alerts = alerts.map { a in
            var a = a
            a.placeNames = a.placeNames.map { $0 == old ? name : $0 }
            return a
        }
        persistPlaces()
        persistAlerts()
    }

    // MARK: Refresh

    /// Asks weather.gov about every saved place. New alerts at or above the chosen severity become a local
    /// notification once, and only once.
    @discardableResult
    func refresh(notify: Bool = true, now: Date = Date()) async -> [WeatherAlert] {
        guard !places.isEmpty, !isChecking else { return [] }
        isChecking = true
        defer { isChecking = false }
        var merged: [String: WeatherAlert] = [:]
        var failures = 0
        for place in places {
            do {
                for alert in try await NWSClient.activeAlerts(at: place.point) {
                    var a = merged[alert.id] ?? alert
                    if !a.placeNames.contains(place.name) { a.placeNames.append(place.name) }
                    merged[alert.id] = a
                }
            } catch {
                failures += 1
            }
        }
        if failures == places.count {
            lastError = "Could not reach weather.gov. Check the connection and try again."
            return []
        }
        lastError = failures > 0 ? "Some places could not be checked." : nil
        let current = Array(merged.values)
        let fresh = WeatherAlertStore.newAlerts(current: current, seen: seen, minimum: minimumSeverity, now: now)
        alerts = current
        lastChecked = now
        // Forget identifiers that have left the feed so the seen list cannot grow forever.
        seen = seen.intersection(current.map(\.id)).union(current.filter { $0.severity >= minimumSeverity }.map(\.id))
        persistAlerts()
        defaults.set(Array(seen), forKey: Keys.seen)
        defaults.set(now, forKey: Keys.lastChecked)
        if notify, notificationsEnabled { await post(fresh) }
        return fresh
    }

    /// Alerts the household has not been told about yet, worst first. Pure, so it is testable.
    nonisolated static func newAlerts(current: [WeatherAlert], seen: Set<String>, minimum: WeatherAlert.Severity, now: Date) -> [WeatherAlert] {
        current.filter { $0.isActive(at: now) && $0.severity >= minimum && !seen.contains($0.id) }
            .sorted { $0.severity > $1.severity }
    }

    private func post(_ fresh: [WeatherAlert]) async {
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional else { return }
        for a in fresh.prefix(5) {
            let content = UNMutableNotificationContent()
            content.title = a.placeNames.isEmpty ? a.event : "\(a.event): \(a.placeNames.joined(separator: ", "))"
            var body = a.untilText() ?? ""
            if !a.instruction.isEmpty { body += (body.isEmpty ? "" : ". ") + a.instruction }
            content.body = body.isEmpty ? a.headline : body
            content.sound = .default
            content.interruptionLevel = a.isWarning ? .timeSensitive : .active
            content.threadIdentifier = "weather"
            try? await center.add(UNNotificationRequest(identifier: "weather-\(a.id)", content: content, trigger: nil))
        }
    }

    // MARK: Geocoding

    /// A ZIP code becomes a coordinate and a town name once, on this phone, through Apple's geocoder.
    nonisolated static func geocode(zip: String) async throws -> (name: String, point: GeoPoint) {
        let marks = try await CLGeocoder().geocodeAddressString("\(zip.trimmingCharacters(in: .whitespaces)), United States")
        guard let mark = marks.first, let loc = mark.location else { throw CocoaError(.coderValueNotFound) }
        let name = [mark.locality, mark.administrativeArea].compactMap { $0 }.joined(separator: ", ")
        return (name.isEmpty ? zip : name, GeoPoint(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude))
    }

    nonisolated static func placeName(for location: CLLocation) async -> String? {
        let marks = try? await CLGeocoder().reverseGeocodeLocation(location)
        guard let mark = marks?.first else { return nil }
        return [mark.locality, mark.administrativeArea].compactMap { $0 }.joined(separator: ", ").nilIfEmpty
    }

    // MARK: Persistence

    private func persistPlaces() {
        defaults.set(try? JSONEncoder().encode(places), forKey: Keys.places)
    }

    private func persistAlerts() {
        defaults.set(try? JSONEncoder().encode(alerts), forKey: Keys.alerts)
    }

    #if DEBUG
    /// Screenshots and the simulator: a place and a live-looking warning without touching the network.
    func loadDemo(now: Date = Date()) {
        let home = AlertPlace(name: "Home", zip: "32801", latitude: 28.5383, longitude: -81.3792)
        let moms = AlertPlace(name: "Mom's house", zip: "32789", latitude: 28.5997, longitude: -81.3393)
        places = [home, moms]
        alerts = [
            WeatherAlert(id: "demo-tornado", event: "Tornado Watch", severity: .severe, urgency: "Expected", certainty: "Possible",
                         headline: "Tornado Watch until 9:00 PM EDT", description: "Scattered severe thunderstorms are expected this afternoon and evening. A few tornadoes, large hail and damaging wind gusts to 70 mph are possible.",
                         instruction: "Review your tornado safety plan. Know where the safest room is, and be ready to move there quickly.",
                         onset: now, ends: now.addingTimeInterval(5 * 3600), expires: now.addingTimeInterval(5 * 3600), areaDesc: "Orange; Seminole", senderName: "NWS Melbourne FL", messageType: "Alert", placeNames: ["Home", "Mom's house"]),
            WeatherAlert(id: "demo-flood", event: "Flood Advisory", severity: .minor, urgency: "Expected", certainty: "Likely",
                         headline: "Flood Advisory until 6:45 PM EDT", description: "Minor flooding of low-lying and poor drainage areas is expected.",
                         instruction: "Turn around, don't drown when encountering flooded roads.",
                         onset: now, ends: now.addingTimeInterval(2 * 3600), expires: now.addingTimeInterval(2 * 3600), areaDesc: "Orange", senderName: "NWS Melbourne FL", messageType: "Alert", placeNames: ["Home"])
        ]
        lastChecked = now.addingTimeInterval(-4 * 60)
    }
    #endif
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

// MARK: - Background refresh

/// iOS wakes the app now and then (its choice, usually a few times a day) to check the feed. This is a
/// backstop, not a siren: Wireless Emergency Alerts and a weather radio stay the fastest warning.
enum WeatherRefreshTask {
    static let identifier = "io.kismetstudio.lantern.weather"

    /// Call once, before the app finishes launching.
    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            guard let refresh = task as? BGAppRefreshTask else { task.setTaskCompleted(success: false); return }
            let work = Task { @MainActor in
                await WeatherAlertStore.shared.refresh(notify: true)
                schedule()
                refresh.setTaskCompleted(success: true)
            }
            refresh.expirationHandler = { work.cancel() }
        }
    }

    /// Ask for the next check. Only when there is something to check.
    @MainActor
    static func schedule(earliest minutes: Double = 30) {
        guard WeatherAlertStore.shared.hasPlaces else {
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
            return
        }
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: minutes * 60)
        try? BGTaskScheduler.shared.submit(request)
    }
}
