import Foundation
import SwiftData

/// One power outage. Started when the lights go out; the fridge and freezer clocks run from it.
@Model
final class OutageEvent {
    var uuid: UUID = UUID()
    var startedAt: Date = Date()
    var endedAt: Date?
    var freezerIsFull: Bool = true
    var fridgeOpenedCount: Int = 0
    var note: String = ""

    init(startedAt: Date = Date()) {
        self.uuid = UUID()
        self.startedAt = startedAt
    }

    var isActive: Bool { endedAt == nil }

    // USDA FSIS: refrigerator about 4 hours if unopened; full freezer about 48 hours, half-full about 24.
    static let fridgeHours: Double = 4
    static let freezerFullHours: Double = 48
    static let freezerHalfHours: Double = 24

    var fridgeDeadline: Date { startedAt.addingTimeInterval(OutageEvent.fridgeHours * 3600) }
    var freezerDeadline: Date { startedAt.addingTimeInterval((freezerIsFull ? OutageEvent.freezerFullHours : OutageEvent.freezerHalfHours) * 3600) }

    func hoursSinceStart(at now: Date = Date()) -> Double { now.timeIntervalSince(startedAt) / 3600 }
}
