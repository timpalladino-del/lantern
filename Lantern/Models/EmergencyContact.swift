import Foundation
import SwiftData

/// A person or number to reach in a bad week. National defaults are seeded; the user adds their own.
@Model
final class EmergencyContact {
    var uuid: UUID = UUID()
    var name: String = ""
    var role: String = ""        // "Utility outage line", "Mom", "Vet"
    var phone: String = ""
    var notes: String = ""
    var isBuiltIn: Bool = false
    var sortOrder: Int = 0
    var createdAt: Date = Date()

    init(name: String, role: String = "", phone: String = "", notes: String = "", isBuiltIn: Bool = false, sortOrder: Int = 0) {
        self.uuid = UUID()
        self.name = name
        self.role = role
        self.phone = phone
        self.notes = notes
        self.isBuiltIn = isBuiltIn
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }

    /// National numbers everyone should have. Seeded once; editable; deletable.
    static let defaults: [(String, String, String, String)] = [
        ("Emergency", "Police, fire, ambulance", "911", "Call when someone is hurt or in danger. If you cannot speak, text 911 where supported."),
        ("Poison Control", "24 hours, free", "1-800-222-1222", "Swallowed, inhaled or splashed something. They will tell you what to do."),
        ("211", "Shelters, food, local help", "211", "Connects you to local services during and after a disaster."),
        ("FEMA Helpline", "Disaster assistance", "1-800-621-3362", "Register for help after a federally declared disaster. Also at disasterassistance.gov."),
        ("Disaster Distress Helpline", "Talk to someone, 24 hours", "1-800-985-5990", "Free, confidential crisis counseling after a disaster.")
    ]
}
