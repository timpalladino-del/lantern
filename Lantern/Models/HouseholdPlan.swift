import Foundation
import SwiftData

/// The plan you write once and read in a panic: where to meet, who to call, where the shutoffs are.
@Model
final class HouseholdPlan {
    var meetNearHome: String = ""          // "The mailbox at the end of the driveway"
    var meetOutsideNeighborhood: String = "" // "The library parking lot on Main"
    var outOfTownContact: String = ""      // "Aunt Pat in Ohio, 555-0100"
    var petsPlan: String = ""              // "Carriers in the hall closet. Sam grabs the cats."
    var kidsPlan: String = ""              // "School pickup: Jo if Sam is at work."
    var medicalNotes: String = ""          // "Dad's insulin is in the fridge door."
    var documentsLocation: String = ""     // "Fireproof box, bedroom closet, key on the hook."

    var gasShutoffNote: String = ""
    @Attribute(.externalStorage) var gasShutoffPhoto: Data?
    var waterShutoffNote: String = ""
    @Attribute(.externalStorage) var waterShutoffPhoto: Data?
    var electricPanelNote: String = ""
    @Attribute(.externalStorage) var electricPanelPhoto: Data?

    var noaaStation: String = ""           // "162.550 MHz, KHB-35"
    var lastReviewedAt: Date?
    var createdAt: Date = Date()

    init() {
        self.createdAt = Date()
    }

    var isEmpty: Bool {
        [meetNearHome, meetOutsideNeighborhood, outOfTownContact, petsPlan, kidsPlan, medicalNotes, documentsLocation,
         gasShutoffNote, waterShutoffNote, electricPanelNote].allSatisfy { $0.isEmpty }
    }
}
