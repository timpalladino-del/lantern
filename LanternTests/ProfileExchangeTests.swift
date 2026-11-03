import XCTest
import SwiftData
@testable import Lantern

@MainActor
final class ProfileExchangeTests: XCTestCase {
    func testCardRoundTripsThroughURL() throws {
        let container = try AppSchema.container(inMemory: true)
        let context = ModelContext(container)
        let p = Person(name: "Maria", age: 42, weightKg: 68, heightCm: 165, sex: .female, activity: .light)
        p.allergies = "Penicillin"
        context.insert(p)
        let m = Medication(name: "Metformin", dose: "500 mg", dosesPerDay: 2, unitsPerDose: 1, unitsOnHand: 48)
        m.scheduleMinutes = [480, 1200]
        m.instructionKeys = ["withFood"]
        m.pharmacy = "CVS"
        m.person = p
        context.insert(m)

        let card = ProfileCard(person: p, sentBy: "Maria")
        let url = try XCTUnwrap(ProfileExchange.importURL(for: card))
        XCTAssertEqual(url.scheme, "https")
        XCTAssertEqual(url.host, "kismetstudio.io")
        XCTAssertTrue(url.path.hasPrefix("/lantern/p/import"))
        guard case .importProfile(let decoded)? = ProfileExchange.route(for: url) else { return XCTFail("no import route") }
        XCTAssertEqual(decoded.name, "Maria")
        XCTAssertEqual(decoded.age, 42)
        XCTAssertEqual(decoded.allergies, "Penicillin")
        XCTAssertEqual(decoded.medications.count, 1)
        XCTAssertEqual(decoded.medications[0].scheduleMinutes, [480, 1200])
        XCTAssertEqual(decoded.medications[0].instructionKeys, ["withFood"])

        // Apply onto a fresh person in another store.
        let container2 = try AppSchema.container(inMemory: true)
        let context2 = ModelContext(container2)
        let q = Person(name: "x")
        context2.insert(q)
        decoded.apply(to: q, in: context2)
        XCTAssertEqual(q.name, "Maria")
        XCTAssertEqual(q.medications.count, 1)
        XCTAssertEqual(q.medications[0].pharmacy, "CVS")
        XCTAssertEqual(q.medications[0].daysOfSupply, 24)
    }

    func testRequestURLRoutesToBuilder() {
        let url = ProfileExchange.requestURL(from: "Tim")
        XCTAssertEqual(ProfileExchange.route(for: url), .newProfile(requestedBy: "Tim"))
        XCTAssertEqual(ProfileExchange.route(for: URL(string: "lantern://profile/new?from=Tim")!), .newProfile(requestedBy: "Tim"))
        XCTAssertEqual(ProfileExchange.route(for: URL(string: "https://kismetstudio.io/lantern/p/new/?from=Tim")!), .newProfile(requestedBy: "Tim"))
        XCTAssertNil(ProfileExchange.route(for: URL(string: "lantern://profile/import?d=not-json")!))
        XCTAssertNil(ProfileExchange.route(for: URL(string: "https://example.com/lantern/p/new")!))
        XCTAssertNil(ProfileExchange.route(for: URL(string: "https://kismetstudio.io/lantern/privacy/")!))
    }

    func testBase64urlHasNoURLUnsafeCharacters() {
        let data = Data((0..<255).map { UInt8($0) })
        let s = ProfileExchange.base64url(data)
        XCTAssertFalse(s.contains("+") || s.contains("/") || s.contains("="))
        XCTAssertEqual(ProfileExchange.fromBase64url(s), data)
    }
}
