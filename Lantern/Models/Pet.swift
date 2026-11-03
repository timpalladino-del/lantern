import Foundation
import SwiftData

enum PetSpecies: String, CaseIterable, Codable, Identifiable {
    case dog, cat, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .dog: return "Dog"
        case .cat: return "Cat"
        case .other: return "Other"
        }
    }
    var defaultWeightKg: Double {
        switch self {
        case .dog: return 20
        case .cat: return 4.5
        case .other: return 5
        }
    }
}

@Model
final class Pet {
    var uuid: UUID = UUID()
    var name: String = ""
    var speciesRaw: String = PetSpecies.dog.rawValue
    var weightKg: Double?
    var foodGramsPerDay: Double?
    var medications: String = ""
    var notes: String = ""
    var createdAt: Date = Date()

    var household: Household?

    init(name: String, species: PetSpecies = .dog, weightKg: Double? = nil) {
        self.uuid = UUID()
        self.name = name
        self.speciesRaw = species.rawValue
        self.weightKg = weightKg
        self.createdAt = Date()
    }

    var species: PetSpecies {
        get { PetSpecies(rawValue: speciesRaw) ?? .other }
        set { speciesRaw = newValue.rawValue }
    }

    /// Roughly 1 US fluid ounce per pound per day, which is about 60 mL per kg.
    var waterLitersPerDay: Double {
        (weightKg ?? species.defaultWeightKg) * 0.06
    }
}
