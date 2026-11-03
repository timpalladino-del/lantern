import Foundation

/// The standard label instructions and warnings, so they are tappable instead of typed, and so the
/// printed card uses the same wording a pharmacist would.
enum MedicationInstruction: String, CaseIterable, Identifiable, Codable {
    // How to take it
    case withFood, emptyStomach, fullGlassWater, doNotCrush, shakeWell, sameTimeDaily, refrigerate, keepDry, finishCourse
    // Warnings
    case noDriving, drowsy, noAlcohol, avoidSun, noGrapefruit, noDairy, noNSAIDs, noAntacids, pregnancy, bleedingRisk, lowSugar, checkBP

    var id: String { rawValue }

    enum Kind: String, CaseIterable { case howToTake = "How to take it", warning = "Warnings" }

    var kind: Kind {
        switch self {
        case .withFood, .emptyStomach, .fullGlassWater, .doNotCrush, .shakeWell, .sameTimeDaily, .refrigerate, .keepDry, .finishCourse:
            return .howToTake
        default:
            return .warning
        }
    }

    var title: String {
        switch self {
        case .withFood: return "Take with food"
        case .emptyStomach: return "Take on an empty stomach"
        case .fullGlassWater: return "Take with a full glass of water"
        case .doNotCrush: return "Swallow whole; do not crush or chew"
        case .shakeWell: return "Shake well before use"
        case .sameTimeDaily: return "Take at the same time every day"
        case .refrigerate: return "Keep refrigerated"
        case .keepDry: return "Keep cool and dry"
        case .finishCourse: return "Finish the full course even if feeling better"
        case .noDriving: return "Do not drive or operate heavy machinery"
        case .drowsy: return "May cause drowsiness"
        case .noAlcohol: return "Avoid alcohol"
        case .avoidSun: return "Avoid prolonged sun exposure"
        case .noGrapefruit: return "Avoid grapefruit and grapefruit juice"
        case .noDairy: return "Do not take with dairy or antacids within 2 hours"
        case .noNSAIDs: return "Do not take with ibuprofen or aspirin"
        case .noAntacids: return "Do not take with antacids"
        case .pregnancy: return "Do not take if pregnant or breastfeeding"
        case .bleedingRisk: return "Increases bleeding risk; tell any doctor or dentist"
        case .lowSugar: return "Can cause low blood sugar; keep sugar nearby"
        case .checkBP: return "Check blood pressure as directed"
        }
    }

    var symbol: String {
        switch self {
        case .withFood: return "fork.knife"
        case .emptyStomach: return "clock"
        case .fullGlassWater: return "waterbottle"
        case .doNotCrush: return "pills"
        case .shakeWell: return "arrow.triangle.2.circlepath"
        case .sameTimeDaily: return "alarm"
        case .refrigerate: return "refrigerator"
        case .keepDry: return "drop"
        case .finishCourse: return "checkmark.circle"
        case .noDriving: return "steeringwheel"
        case .drowsy: return "moon.zzz"
        case .noAlcohol: return "wineglass"
        case .avoidSun: return "sun.max.trianglebadge.exclamationmark"
        case .noGrapefruit: return "leaf"
        case .noDairy: return "cup.and.saucer"
        case .noNSAIDs: return "pills"
        case .noAntacids: return "pills"
        case .pregnancy: return "figure.and.child.holdinghands"
        case .bleedingRisk: return "bandage"
        case .lowSugar: return "cube"
        case .checkBP: return "heart.text.square"
        }
    }

    static func all(of kind: Kind) -> [MedicationInstruction] { allCases.filter { $0.kind == kind } }
}
