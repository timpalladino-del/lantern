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
    /// Universal links. Opens the app when installed; otherwise a page on the site explains and offers the app.
    static let webHost = "kismetstudio.io"
    static let webPath = "/lantern/p"

    enum Route: Equatable {
        case newProfile(requestedBy: String, forName: String)
        case importProfile(ProfileCard)
    }

    /// `https://kismetstudio.io/lantern/p/new?from=Tim`: opens the profile builder on the family member's phone.
    /// Where to get the app. Live once Lantern is on the App Store; until then the site page explains.
    static let appStoreURL = URL(string: "https://apps.apple.com/app/id6830418364")!

    static func requestURL(from requester: String, forName: String = "") -> URL {
        var c = URLComponents()
        c.scheme = "https"
        c.host = webHost
        c.path = webPath + "/new"
        var items = [URLQueryItem(name: "from", value: requester)]
        if !forName.isEmpty { items.append(URLQueryItem(name: "for", value: forName)) }
        c.queryItems = items
        return c.url!
    }

    /// `https://kismetstudio.io/lantern/p/import?d=<base64url json>`: taps straight into the owner's household.
    static func importURL(for card: ProfileCard) -> URL? {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        guard let data = try? enc.encode(card) else { return nil }
        var c = URLComponents()
        c.scheme = "https"
        c.host = webHost
        c.path = webPath + "/import"
        c.queryItems = [URLQueryItem(name: "d", value: base64url(data))]
        return c.url
    }

    /// Accepts both the universal link form and the older `lantern://profile/...` form.
    static func route(for url: URL) -> Route? {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        let action: String
        if url.scheme == scheme, url.host == "profile" {
            action = comps.path
        } else if url.scheme == "https", url.host == webHost, comps.path.hasPrefix(webPath + "/") {
            action = String(comps.path.dropFirst(webPath.count))
        } else {
            return nil
        }
        let q = Dictionary(uniqueKeysWithValues: (comps.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        switch action.hasSuffix("/") ? String(action.dropLast()) : action {
        case "/new":
            return .newProfile(requestedBy: q["from"] ?? "", forName: q["for"] ?? "")
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
    static func requestMessage(from requester: String, forName: String = "") -> String {
        let who = forName.isEmpty ? "you" : forName
        let greeting = forName.isEmpty ? "" : "Hi \(forName), "
        return """
        \(greeting)\(requester) is setting up Lantern, our household emergency app, and needs a few details from \(who): age, any medications (dose and when you take them), and allergies.

        1. Get Lantern on your iPhone: \(appStoreURL.absoluteString)
        2. Open it once and tap Next through the welcome.
        3. Come back here and tap your link: \(requestURL(from: requester, forName: forName).absoluteString)
        4. Fill in your profile and tap "Send to \(requester)".

        Everything stays on our phones. Nothing goes to a server.
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
