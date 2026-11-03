import Foundation
import SwiftData

/// A person's profile as something that can travel in a link: no server, no account. The household
/// owner sends a request link; the family member fills in their own profile in Lantern and sends it
/// back as another link; the owner taps it and the person lands in the household.
struct ProfileCard: Codable, Equatable {
    struct MedicationCard: Codable, Equatable {
        var name: String
        var dose: String
        var form: String
        var purpose: String
        var dosesPerDay: Double
        var unitsPerDose: Double
        var unitsOnHand: Double
        var isCritical: Bool
        var expirationDate: Date?
        var scheduleMinutes: [Int]
        var instructionKeys: [String]
        var customInstructions: String
        var prescriber: String
        var prescriberPhone: String
        var pharmacy: String
        var pharmacyPhone: String
        var rxNumber: String
        var notes: String
    }

    var version: Int = 1
    var name: String
    var age: Int?
    var weightKg: Double?
    var heightCm: Double?
    var sex: String
    var activity: String
    var allergies: String
    var dietaryNotes: String
    var notes: String
    var medications: [MedicationCard]
    var sentBy: String = ""
    var createdAt: Date = Date()

    init(person p: Person, sentBy: String = "") {
        name = p.name
        age = p.age
        weightKg = p.weightKg
        heightCm = p.heightCm
        sex = p.sexRaw
        activity = p.activityRaw
        allergies = p.allergies
        dietaryNotes = p.dietaryNotes
        notes = p.notes
        medications = p.medications.sorted { $0.createdAt < $1.createdAt }.map { m in
            MedicationCard(name: m.name, dose: m.dose, form: m.formRaw, purpose: m.purpose, dosesPerDay: m.dosesPerDay,
                           unitsPerDose: m.unitsPerDose, unitsOnHand: m.unitsOnHand, isCritical: m.isCritical,
                           expirationDate: m.expirationDate, scheduleMinutes: m.scheduleMinutes, instructionKeys: m.instructionKeys,
                           customInstructions: m.customInstructions, prescriber: m.prescriber, prescriberPhone: m.prescriberPhone,
                           pharmacy: m.pharmacy, pharmacyPhone: m.pharmacyPhone, rxNumber: m.rxNumber, notes: m.notes)
        }
        self.sentBy = sentBy
        self.createdAt = Date()
    }

    /// Writes the card onto a person. Medications are replaced, not merged: the card is the newer truth.
    func apply(to p: Person, in context: ModelContext) {
        p.name = name
        p.age = age
        p.weightKg = weightKg
        p.heightCm = heightCm
        p.sexRaw = sex
        p.activityRaw = activity
        p.allergies = allergies
        p.dietaryNotes = dietaryNotes
        p.notes = notes
        for old in p.medications { context.delete(old) }
        for c in medications {
            let m = Medication(name: c.name, dose: c.dose, dosesPerDay: c.dosesPerDay, unitsPerDose: c.unitsPerDose, unitsOnHand: c.unitsOnHand, isCritical: c.isCritical)
            m.formRaw = c.form
            m.purpose = c.purpose
            m.expirationDate = c.expirationDate
            m.scheduleMinutes = c.scheduleMinutes
            m.instructionKeys = c.instructionKeys
            m.customInstructions = c.customInstructions
            m.prescriber = c.prescriber
            m.prescriberPhone = c.prescriberPhone
            m.pharmacy = c.pharmacy
            m.pharmacyPhone = c.pharmacyPhone
            m.rxNumber = c.rxNumber
            m.notes = c.notes
            m.person = p
            context.insert(m)
        }
    }

    var summary: String {
        var parts: [String] = []
        if let a = age { parts.append("\(a) years old") }
        parts.append(medications.isEmpty ? "no medications" : (medications.count == 1 ? "1 medication" : "\(medications.count) medications"))
        if !allergies.isEmpty { parts.append("allergies: \(allergies)") }
        return parts.joined(separator: " · ")
    }
}

enum ProfileExchange {
    static let scheme = "lantern"

    enum Route: Equatable {
        case newProfile(requestedBy: String)
        case importProfile(ProfileCard)
    }

    /// `lantern://profile/new?from=Tim`: opens the profile builder on the family member's phone.
    static func requestURL(from requester: String) -> URL {
        var c = URLComponents()
        c.scheme = scheme
        c.host = "profile"
        c.path = "/new"
        c.queryItems = [URLQueryItem(name: "from", value: requester)]
        return c.url!
    }

    /// `lantern://profile/import?d=<base64url json>`: taps straight into the owner's household.
    static func importURL(for card: ProfileCard) -> URL? {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        guard let data = try? enc.encode(card) else { return nil }
        var c = URLComponents()
        c.scheme = scheme
        c.host = "profile"
        c.path = "/import"
        c.queryItems = [URLQueryItem(name: "d", value: base64url(data))]
        return c.url
    }

    static func route(for url: URL) -> Route? {
        guard url.scheme == scheme, url.host == "profile",
              let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        let q = Dictionary(uniqueKeysWithValues: (comps.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        switch comps.path {
        case "/new":
            return .newProfile(requestedBy: q["from"] ?? "")
        case "/import":
            guard let d = q["d"], let data = fromBase64url(d) else { return nil }
            let dec = JSONDecoder()
            dec.dateDecodingStrategy = .iso8601
            guard let card = try? dec.decode(ProfileCard.self, from: data) else { return nil }
            return .importProfile(card)
        default:
            return nil
        }
    }

    /// What the owner sends. Plain text so it works in Messages, WhatsApp, email, anything.
    static func requestMessage(from requester: String) -> String {
        """
        \(requester) is setting up Lantern for the household and needs your details: age, any medications \
        (dose and when you take them), and allergies. It all stays on your phones; nothing goes to a server.

        Open this on your iPhone with Lantern installed and fill in your own profile:
        \(requestURL(from: requester).absoluteString)

        Don't have Lantern yet? Get it from the App Store, then tap the link again.
        """
    }

    /// What the family member sends back.
    static func replyMessage(for card: ProfileCard) -> String? {
        guard let url = importURL(for: card) else { return nil }
        return """
        Here is my Lantern profile (\(card.name): \(card.summary)). Tap on your iPhone to add me to the household:
        \(url.absoluteString)
        """
    }

    static func base64url(_ data: Data) -> String {
        data.base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }

    static func fromBase64url(_ s: String) -> Data? {
        var b = s.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        while b.count % 4 != 0 { b += "=" }
        return Data(base64Encoded: b)
    }
}
