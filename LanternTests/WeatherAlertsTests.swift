import XCTest
@testable import Lantern

final class WeatherAlertsTests: XCTestCase {
    private let fixture = """
    {"features":[
      {"properties":{"id":"urn:a","event":"High Wind Watch","severity":"Severe","urgency":"Future","certainty":"Possible",
        "headline":"High Wind Watch issued November 7 at 11:00AM MST until November 8 at 8:00PM MST by NWS Great Falls MT",
        "description":"* WHAT...Southwest winds 25 to 40 mph.\\n\\n* WHERE...Cascade County.","instruction":"Monitor the latest forecasts\\nand warnings for updates.",
        "onset":"2026-11-08T08:00:00-07:00","ends":"2026-11-08T20:00:00-07:00","expires":"2026-11-08T05:00:00-07:00","effective":"2026-11-07T11:00:00-07:00",
        "areaDesc":"Eastern Toole and Liberty; Hill County","senderName":"NWS Great Falls MT","messageType":"Update","status":"Actual","response":"Prepare"}},
      {"properties":{"id":"urn:test","event":"Tornado Warning","severity":"Extreme","urgency":"Immediate","certainty":"Observed",
        "headline":"Test","description":"","instruction":null,"onset":null,"ends":null,"expires":"2026-11-08T05:00:00-07:00","areaDesc":"X","senderName":"NWS","messageType":"Alert","status":"Test"}},
      {"properties":{"id":"urn:b","event":"Flood Advisory","severity":"Minor","urgency":"Expected","certainty":"Likely",
        "headline":"Flood Advisory","description":"Minor flooding.","instruction":"Turn around, don't drown.","onset":null,"ends":null,"expires":null,
        "areaDesc":"Orange","senderName":"NWS Melbourne FL","messageType":"Alert","status":"Actual"}}
    ]}
    """

    func testParseDropsTestMessagesAndKeepsFields() throws {
        let alerts = try NWSClient.parse(Data(fixture.utf8))
        XCTAssertEqual(alerts.map(\.id), ["urn:a", "urn:b"], "the Test-status message is dropped")
        let a = alerts[0]
        XCTAssertEqual(a.event, "High Wind Watch")
        XCTAssertEqual(a.severity, .severe)
        XCTAssertEqual(a.instruction, "Monitor the latest forecasts and warnings for updates.")
        XCTAssertTrue(a.description.contains("\n\n* WHERE"), "paragraph breaks survive, single wraps are joined")
        XCTAssertNotNil(a.onset)
        XCTAssertEqual(a.endsAt, a.ends, "ends is later than expires here")
        XCTAssertFalse(a.isWarning)
        XCTAssertTrue(alerts[1].isActive(at: .distantFuture), "no end means it stays until the feed drops it")
    }

    func testSeverityOrderAndLabels() {
        XCTAssertEqual(WeatherAlert.Severity(label: "Extreme"), .extreme)
        XCTAssertEqual(WeatherAlert.Severity(label: "nonsense"), .unknown)
        XCTAssertTrue(WeatherAlert.Severity.minor < .moderate)
        XCTAssertTrue(WeatherAlert.Severity.severe < .extreme)
    }

    func testNewAlertsRespectSeenAndMinimum() throws {
        let alerts = try NWSClient.parse(Data(fixture.utf8))
        let now = ISO8601DateFormatter().date(from: "2026-11-08T10:00:00-07:00")!
        let fresh = WeatherAlertStore.newAlerts(current: alerts, seen: [], minimum: .severe, now: now)
        XCTAssertEqual(fresh.map(\.id), ["urn:a"], "the minor advisory is below the bar")
        let all = WeatherAlertStore.newAlerts(current: alerts, seen: [], minimum: .unknown, now: now)
        XCTAssertEqual(all.map(\.id), ["urn:a", "urn:b"], "worst first")
        let none = WeatherAlertStore.newAlerts(current: alerts, seen: ["urn:a", "urn:b"], minimum: .unknown, now: now)
        XCTAssertTrue(none.isEmpty)
        let later = ISO8601DateFormatter().date(from: "2026-11-09T10:00:00-07:00")!
        XCTAssertEqual(WeatherAlertStore.newAlerts(current: alerts, seen: [], minimum: .severe, now: later).count, 0, "expired alerts never notify")
    }

    func testZIPValidation() {
        XCTAssertTrue(AlertPlace.isValidZIP("32801"))
        XCTAssertTrue(AlertPlace.isValidZIP(" 32801-1234 "))
        XCTAssertFalse(AlertPlace.isValidZIP("3280"))
        XCTAssertFalse(AlertPlace.isValidZIP("32801-12"))
        XCTAssertFalse(AlertPlace.isValidZIP("ABCDE"))
    }

    func testRequestURLUsesPointAndActualStatus() {
        let url = NWSClient.url(for: GeoPoint(latitude: 28.53831, longitude: -81.37924))
        XCTAssertEqual(url.absoluteString, "https://api.weather.gov/alerts/active?status=actual&point=28.5383,-81.3792")
    }

    @MainActor
    func testStoreAddRemoveAndPersistence() {
        let suite = "lantern-tests-weather"
        let d = UserDefaults(suiteName: suite)!
        d.removePersistentDomain(forName: suite)
        let store = WeatherAlertStore(defaults: d)
        XCTAssertFalse(store.hasPlaces)
        XCTAssertEqual(store.minimumSeverity, .severe, "default bar is Severe")
        let home = AlertPlace(name: "Home", zip: "32801", latitude: 28.5, longitude: -81.4)
        store.add(home)
        store.add(AlertPlace(name: "home", zip: "32801", latitude: 28.5, longitude: -81.4))
        XCTAssertEqual(store.places.count, 1, "same name twice is one place")
        let again = WeatherAlertStore(defaults: d)
        XCTAssertEqual(again.places, [home])
        again.remove(home)
        XCTAssertFalse(again.hasPlaces)
    }
}
