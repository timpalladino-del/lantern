import Foundation

struct KitTemplate: Codable, Identifiable, Hashable {
    let key: String
    let kind: String
    let name: String
    let summary: String
    let source: String
    let items: [StarterPackItem]
    var id: String { key }
    var kitKind: KitKind { KitKind(rawValue: kind) ?? .other }
}

/// Ready-made kit lists (go-bag, car, pet) so a kit starts with a checklist instead of an empty bag.
final class KitLibrary {
    static let shared = KitLibrary()

    struct File: Codable {
        let version: Int
        let templates: [KitTemplate]
    }

    let templates: [KitTemplate]

    init(templates: [KitTemplate]) { self.templates = templates }

    convenience init(bundle: Bundle = .main) {
        if let url = bundle.url(forResource: "kits", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let file = try? JSONDecoder().decode(File.self, from: data) {
            self.init(templates: file.templates)
        } else {
            self.init(templates: [])
        }
    }

    func template(_ key: String?) -> KitTemplate? {
        guard let key else { return nil }
        return templates.first { $0.key == key }
    }

    /// Template lines with no item of a similar name in the kit yet.
    static func missing(from template: KitTemplate, in kit: Kit) -> [StarterPackItem] {
        let have = kit.items.map { $0.name.lowercased() }
        return template.items.filter { line in
            let n = line.name.lowercased()
            return !have.contains { $0.contains(n) || n.contains($0) }
        }
    }
}
