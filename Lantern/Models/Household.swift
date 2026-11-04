import Foundation
import SwiftData

/// One row. The people and pets it covers and how many days you are aiming for.
@Model
final class Household {
    /// Kept for the first-run default before anyone is added. Once `people` has entries, they win.
    var adults: Int = 2
    var children: Int = 0
    var pets: Int = 0
    /// Days of supply you want on hand. Red Cross: 3 to evacuate, 14 at home.
    var targetDays: Int = 14
    var region: String = ""
    var createdAt: Date = Date()
    /// The person who sends invitations and whose name appears on them. Defaults to the first person.
    var adminPersonUUID: UUID?

    @Relationship(deleteRule: .cascade, inverse: \Person.household)
    var people: [Person] = []

    @Relationship(deleteRule: .cascade, inverse: \Pet.household)
    var petList: [Pet] = []

    init(adults: Int = 2, children: Int = 0, pets: Int = 0, targetDays: Int = 14) {
        self.adults = adults
        self.children = children
        self.pets = pets
        self.targetDays = targetDays
        self.createdAt = Date()
    }

    var hasPeople: Bool { !people.isEmpty }

    var admin: Person? {
        if let id = adminPersonUUID, let p = people.first(where: { $0.uuid == id }) { return p }
        return sortedPeople.first
    }

    /// Headcount for water math: real people when listed, otherwise the placeholder counts.
    var peopleCount: Int {
        hasPeople ? people.count : max(1, adults + children)
    }

    var petCount: Int {
        petList.isEmpty ? max(0, pets) : petList.count
    }

    /// Calories the whole household needs per day. Falls back to 2,000 per adult and 1,400 per child.
    var caloriesPerDay: Double {
        if hasPeople { return people.reduce(0) { $0 + $1.dailyCalories } }
        return Double(max(1, adults)) * 2000 + Double(max(0, children)) * 1400
    }

    var infants: [Person] { people.filter(\.isInfant) }

    var sortedPeople: [Person] { people.sorted { $0.sortOrder != $1.sortOrder ? $0.sortOrder < $1.sortOrder : $0.createdAt < $1.createdAt } }

    var allMedications: [Medication] { people.flatMap(\.medications) }
}
