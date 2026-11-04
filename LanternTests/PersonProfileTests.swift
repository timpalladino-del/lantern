import XCTest
import SwiftData
@testable import Lantern

final class PersonProfileTests: XCTestCase {
    func testCustomFieldsRoundTrip() {
        let p = Person(name: "Maria")
        p.customFields = [CustomField(label: "Glasses", value: "-2.5"), CustomField(label: "School", value: "Lincoln Elementary")]
        XCTAssertEqual(p.customFields.count, 2)
        XCTAssertEqual(p.customFields.first?.label, "Glasses")
        p.customFields = []
        XCTAssertEqual(p.customFieldsJSON, "[]")
        XCTAssertTrue(p.customFields.isEmpty)
    }

    func testInitialsAndBareProfile() {
        let p = Person(name: "Maria Alvarez")
        XCTAssertEqual(p.initials, "MA")
        XCTAssertTrue(p.profileIsBare)
        p.skillKeys = ["cpr"]
        XCTAssertFalse(p.profileIsBare)
        XCTAssertEqual(p.skills.map(\.title), ["CPR / AED"])
        XCTAssertEqual(Person(name: "").initials, "?")
    }

    func testPowerDevicesAndMobility() {
        let p = Person(name: "Leo")
        XCTAssertFalse(p.dependsOnPower)
        p.powerDeviceKeys = ["cpap", "nope"]
        XCTAssertTrue(p.dependsOnPower)
        XCTAssertEqual(p.powerDevices.map(\.key), ["cpap"])
        p.mobility = .wheelchair
        XCTAssertTrue(p.mobility.needsHelpToLeave)
    }

    func testSkillLibraryHasEveryGroupAndUniqueKeys() {
        for g in SkillGroup.allCases {
            XCTAssertTrue(SkillLibrary.all.contains { $0.group == g }, "no skills in \(g)")
        }
        XCTAssertEqual(Set(SkillLibrary.all.map(\.key)).count, SkillLibrary.all.count)
        XCTAssertEqual(Set(PowerDevice.all.map(\.key)).count, PowerDevice.all.count)
        for k in SkillLibrary.coreKeys { XCTAssertNotNil(SkillLibrary.skill(k)) }
    }

    func testProfileCardCarriesTheFullerProfile() throws {
        let p = Person(name: "Maria", age: 42)
        p.skillKeys = ["first_aid", "cpr"]
        p.powerDeviceKeys = ["insulin"]
        p.bloodType = .aNeg
        p.conditions = "Type 2 diabetes"
        p.emergencyRole = "Grabs the medication bag"
        p.customFields = [CustomField(label: "Glasses", value: "-2.5")]
        let card = ProfileCard(person: p)
        XCTAssertEqual(card.version, 2)
        let data = try JSONEncoder().encode(card)
        let back = try JSONDecoder().decode(ProfileCard.self, from: data)
        XCTAssertEqual(back.skillKeys, ["first_aid", "cpr"])
        XCTAssertEqual(back.bloodType, "A-")
        XCTAssertTrue(back.summary.contains("2 skills"))
        XCTAssertTrue(back.summary.contains("needs power"))

        let container = try AppSchema.container(inMemory: true)
        let context = ModelContext(container)
        let q = Person(name: "x")
        context.insert(q)
        back.apply(to: q, in: context)
        XCTAssertEqual(q.skillKeys, ["first_aid", "cpr"])
        XCTAssertEqual(q.bloodType, .aNeg)
        XCTAssertEqual(q.customFields.first?.label, "Glasses")
        XCTAssertEqual(q.emergencyRole, "Grabs the medication bag")
    }

    func testOldCardWithoutVersionTwoFieldsStillDecodes() throws {
        let json = """
        {"version":1,"name":"Sam","sex":"male","activity":"light","allergies":"","dietaryNotes":"","notes":"","medications":[],"sentBy":"","createdAt":0,"householdToken":""}
        """
        let card = try JSONDecoder().decode(ProfileCard.self, from: Data(json.utf8))
        XCTAssertEqual(card.name, "Sam")
        XCTAssertNil(card.skillKeys)
    }
}
