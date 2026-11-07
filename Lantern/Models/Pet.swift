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
    /// What they eat, so pet food on the shelf can be turned into days. Cups of dry (about 350 kcal) and
    /// cans of wet (about 400 kcal) per day; blank means estimate from weight.
    var foodCupsPerDay: Double?
    var foodCansPerDay: Double?
    var foodBrand: String = ""
    var prescriptionDiet: Bool = false
    var medications: String = ""
    var notes: String = ""
    var createdAt: Date = Date()

    // Records a shelter, a vet or a stranger will ask for.
    var microchip: String = ""
    var microchipRegistry: String = ""      // "HomeAgain", "AKC Reunite": where the chip number is registered
    var vet: String = ""
    var vetPhone: String = ""
    var carrierLocation: String = ""        // "Hall closet, top shelf"
    var caregiverName: String = ""          // who takes the pet if we cannot
    var caregiverPhone: String = ""
    var lodgingNotes: String = ""           // pet-friendly hotels, boarding, a relative's house
    @Attribute(.externalStorage)
    var vaccinationPhotoData: Data?
    /// The pet itself. Shelters and finders ask for one; a photo of you together proves ownership.
    @Attribute(.externalStorage)
    var photoData: Data?

    var household: Household?

    /// One line for the printed plan: "Biscuit (dog): chip 985112000, HomeAgain. Vet Dr. Ruiz (407) 555-0101. Carrier: hall closet."
    var planLine: String {
        var parts: [String] = []
        if !microchip.isEmpty { parts.append("chip \(microchip)" + (microchipRegistry.isEmpty ? "" : ", \(microchipRegistry)")) }
        if !vet.isEmpty { parts.append("Vet \(vet)" + (vetPhone.isEmpty ? "" : " \(vetPhone)")) }
        if !carrierLocation.isEmpty { parts.append("Carrier: \(carrierLocation)") }
        if !caregiverName.isEmpty { parts.append("If we can't: \(caregiverName)" + (caregiverPhone.isEmpty ? "" : " \(caregiverPhone)")) }
        if !lodgingNotes.isEmpty { parts.append("Where we'd stay: \(lodgingNotes)") }
        if !medications.isEmpty { parts.append("Meds: \(medications)") }
        let head = "\(name) (\(species.title.lowercased()))"
        return parts.isEmpty ? head : head + ": " + parts.joined(separator: ". ") + "."
    }

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

    static let kcalPerCupDry: Double = 350
    static let kcalPerCanWet: Double = 400

    /// Calories a day. What the owner says they feed wins; otherwise resting energy (70 × kg^0.75) times a
    /// typical adult factor (WSAVA: about 1.6 for dogs, 1.2 for cats).
    var foodKcalPerDay: Double {
        let fed = (foodCupsPerDay ?? 0) * Pet.kcalPerCupDry + (foodCansPerDay ?? 0) * Pet.kcalPerCanWet
        if fed > 0 { return fed }
        if let g = foodGramsPerDay, g > 0 { return g * 3.5 }
        let kg = weightKg ?? species.defaultWeightKg
        let rer = 70 * pow(kg, 0.75)
        switch species {
        case .dog: return rer * 1.6
        case .cat: return rer * 1.2
        case .other: return rer * 1.4
        }
    }

    var foodIsEstimated: Bool { (foodCupsPerDay ?? 0) + (foodCansPerDay ?? 0) == 0 && (foodGramsPerDay ?? 0) == 0 }
}
