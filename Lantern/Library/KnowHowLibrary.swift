import Foundation

struct KnowHowCard: Codable, Identifiable, Hashable {
    let key: String
    let title: String
    let category: String
    let symbol: String
    let summary: String
    let steps: [String]
    let source: String
    let sourceURL: String?
    var id: String { key }
}

/// Short, sourced cards that work with no signal.
final class KnowHowLibrary {
    static let shared = KnowHowLibrary()

    struct File: Codable {
        let version: Int
        let disclaimer: String
        let cards: [KnowHowCard]
    }

    let cards: [KnowHowCard]
    let disclaimer: String

    init(cards: [KnowHowCard], disclaimer: String) {
        self.cards = cards
        self.disclaimer = disclaimer
    }

    convenience init(bundle: Bundle = .main) {
        if let url = bundle.url(forResource: "knowhow", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let file = try? JSONDecoder().decode(File.self, from: data) {
            self.init(cards: file.cards, disclaimer: file.disclaimer)
        } else {
            self.init(cards: [], disclaimer: "")
        }
    }

    var categories: [String] {
        var seen: [String] = []
        for c in cards where !seen.contains(c.category) { seen.append(c.category) }
        return seen
    }

    func cards(in category: String) -> [KnowHowCard] { cards.filter { $0.category == category } }
    func card(_ key: String) -> KnowHowCard? { cards.first { $0.key == key } }
}

/// NOAA Weather Radio broadcasts on seven frequencies nationwide. The user notes which one works at home.
enum RadioReference {
    static let noaaFrequencies: [String] = ["162.400", "162.425", "162.450", "162.475", "162.500", "162.525", "162.550"]
    static let noaaNote = "All seven are in MHz. Scan them on a weather radio; the one that comes in clearly is your station. Most radios also take a county code (SAME) so they only alarm for your area. Find yours at weather.gov/nwr."
}
