import Foundation

struct MedicationEntry: Codable, Identifiable, Hashable {
    let generic: String
    let brands: [String]
    let strengths: [String]
    let purpose: String
    let form: String
    let instructionKeys: [String]
    let critical: Bool
    var id: String { generic }

    var displayName: String {
        brands.isEmpty ? generic : "\(generic) (\(brands.prefix(2).joined(separator: ", ")))"
    }
    var medicationForm: MedicationForm { MedicationForm(rawValue: form) ?? .tablet }
}

/// Common US prescriptions and over-the-counter medicines, searchable by generic, brand or purpose, with
/// forgiveness for spelling. People are rarely holding the bottle when they type.
final class MedicationLibrary {
    static let shared = MedicationLibrary()

    struct File: Codable {
        let version: Int
        let medications: [MedicationEntry]
    }

    let entries: [MedicationEntry]

    init(entries: [MedicationEntry]) { self.entries = entries }

    convenience init(bundle: Bundle = .main) {
        if let url = bundle.url(forResource: "medications", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let file = try? JSONDecoder().decode(File.self, from: data) {
            self.init(entries: file.medications)
        } else {
            self.init(entries: [])
        }
    }

    func search(_ query: String, limit: Int = 30) -> [MedicationEntry] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty { return Array(entries.sorted { $0.generic < $1.generic }.prefix(limit)) }
        let scored: [(MedicationEntry, Int)] = entries.compactMap { e in
            let names = [e.generic] + e.brands
            var best = 0
            for n in names {
                let s = MedicationLibrary.score(query: q, against: n.lowercased())
                best = max(best, s)
            }
            if e.purpose.lowercased().contains(q) { best = max(best, MedicationLibrary.purposeScore) }
            return best > 0 ? (e, best) : nil
        }
        return scored.sorted { a, b in a.1 != b.1 ? a.1 > b.1 : a.0.generic < b.0.generic }.prefix(limit).map { $0.0 }
    }

    /// 50 prefix of the whole name, 40 prefix of any word, 30 contains, 20 minus the edit distance for a
    /// close spelling (so the nearest spelling wins), 0 no match. Purpose matches score 10.
    static let purposeScore = 10

    static func score(query q: String, against name: String) -> Int {
        if name.hasPrefix(q) { return 50 }
        let words = name.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
        if words.contains(where: { $0.hasPrefix(q) }) { return 40 }
        if name.contains(q) { return 30 }
        guard q.count >= 4 else { return 0 }
        let tolerance = q.count >= 8 ? 3 : 2
        var best = 0
        for w in words where abs(w.count - q.count) <= tolerance {
            let d = levenshtein(q, w)
            if d <= tolerance { best = max(best, 20 - d) }
            // also compare against the first q.count letters of the word (typing a misspelled start)
            if w.count > q.count {
                let dp = levenshtein(q, String(w.prefix(q.count)))
                if dp <= tolerance - 1 { best = max(best, 20 - dp - 1) }
            }
        }
        return best
    }

    static func levenshtein(_ a: String, _ b: String) -> Int {
        let a = Array(a), b = Array(b)
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        var prev = Array(0...b.count)
        var cur = [Int](repeating: 0, count: b.count + 1)
        for i in 1...a.count {
            cur[0] = i
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                cur[j] = min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost)
            }
            swap(&prev, &cur)
        }
        return prev[b.count]
    }
}
