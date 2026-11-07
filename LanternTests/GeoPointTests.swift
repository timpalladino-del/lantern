import XCTest
@testable import Lantern

final class GeoPointTests: XCTestCase {
    func testParsePlainPairs() {
        XCTAssertEqual(GeoPoint.parse("28.5383, -81.3792"), GeoPoint(latitude: 28.5383, longitude: -81.3792))
        XCTAssertEqual(GeoPoint.parse(" 28.5383 -81.3792 "), GeoPoint(latitude: 28.5383, longitude: -81.3792))
        XCTAssertEqual(GeoPoint.parse("-33.9, 151.2"), GeoPoint(latitude: -33.9, longitude: 151.2))
    }

    func testParseMapsLinks() {
        XCTAssertEqual(GeoPoint.parse("https://maps.apple.com/?ll=28.5383,-81.3792&q=Home"), GeoPoint(latitude: 28.5383, longitude: -81.3792))
        XCTAssertEqual(GeoPoint.parse("https://www.google.com/maps/@28.5383,-81.3792,17z"), GeoPoint(latitude: 28.5383, longitude: -81.3792))
    }

    func testRejectsNonsense() {
        XCTAssertNil(GeoPoint.parse("the mailbox"))
        XCTAssertNil(GeoPoint.parse("0, 0"), "null island is not a meeting place")
        XCTAssertNil(GeoPoint.parse("95, 10"), "latitude out of range")
    }

    func testFormats() {
        let p = GeoPoint(latitude: 28.5383, longitude: -81.3792)
        XCTAssertEqual(p.text, "28.53830, -81.37920")
        XCTAssertTrue(p.dms.hasSuffix(" W"))
        XCTAssertTrue(p.dms.hasPrefix("28°32'"))
        XCTAssertTrue(p.mapsURL.absoluteString.contains("ll=28.5383,-81.3792"))
    }

    func testDistanceText() {
        XCTAssertEqual(GeoPoint.distanceText(30), "98 ft away")
        XCTAssertEqual(GeoPoint.distanceText(5000), "3.1 mi away")
        let a = GeoPoint(latitude: 28.5383, longitude: -81.3792), b = GeoPoint(latitude: 28.5483, longitude: -81.3792)
        XCTAssertEqual(a.distance(to: b), 1110, accuracy: 20)
    }
}
