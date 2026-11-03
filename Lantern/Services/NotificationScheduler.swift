import Foundation
import UserNotifications

/// Local notifications only. Scheduled by iOS, so they fire with no network and no server.
/// Default is one weekly digest. Per-item pings are reserved for medicine, water rotation and equipment.
@MainActor
final class NotificationScheduler {
    static let shared = NotificationScheduler()

    static let digestIdentifier = "weekly-digest"

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// Rebuilds every scheduled notification from the current data. Call after edits.
    func reschedule(items: [SupplyItem],
                    tasks: [MaintenanceTask],
                    medications: [Medication] = [],
                    digestWeekday: Int,
                    digestHour: Int,
                    now: Date = Date()) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        await scheduleMedicationReminders(for: medications)

        // Weekly digest
        let soon = items.filter { item in
            switch item.status(on: now) {
            case .soon, .past: return true
            default: return false
            }
        }
        let dueTasks = tasks.filter { $0.isDue(on: now) || $0.daysUntilDue(from: now) <= 7 }

        let digest = UNMutableNotificationContent()
        digest.title = "Your week, supplies-wise"
        digest.body = digestBody(itemCount: soon.count, taskCount: dueTasks.count, firstItem: soon.first?.name)
        digest.sound = .default
        var comps = DateComponents()
        comps.weekday = digestWeekday
        comps.hour = digestHour
        comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        try? await center.add(UNNotificationRequest(identifier: NotificationScheduler.digestIdentifier, content: digest, trigger: trigger))

        // Per-item: medicine, baby items, and water rotation only.
        for item in items where [.medicine, .baby, .water].contains(item.category) {
            guard let exp = item.expirationDate, exp > now else { continue }
            let leadDays = item.category == .water ? 7 : 14
            guard let fire = Calendar.current.date(byAdding: .day, value: -leadDays, to: exp), fire > now else { continue }
            let content = UNMutableNotificationContent()
            content.title = item.category == .water ? "Time to rotate water" : "\(item.name) is due soon"
            content.body = item.category == .water
                ? "\(item.name) was filled or bought a while ago. Refill or replace it this week."
                : "Expires \(exp.formatted(date: .abbreviated, time: .omitted)). Check it and restock if needed."
            content.sound = .default
            let fireComps = Calendar.current.dateComponents([.year, .month, .day], from: fire)
            var at = fireComps
            at.hour = digestHour
            let t = UNCalendarNotificationTrigger(dateMatching: at, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: "item-\(item.uuid.uuidString)", content: content, trigger: t))
        }

        // Equipment tasks: one notification on the due day. Part of Family; Free sees due dates in the app only.
        for task in tasks where task.isEnabled && PlanStore.shared.plan.isPaid {
            let due = task.nextDue
            guard due > now else { continue }
            let content = UNMutableNotificationContent()
            content.title = task.equipment?.name ?? "Equipment check"
            content.body = task.title
            content.sound = .default
            var at = Calendar.current.dateComponents([.year, .month, .day], from: due)
            at.hour = digestHour
            let t = UNCalendarNotificationTrigger(dateMatching: at, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: "task-\(task.uuid.uuidString)", content: content, trigger: t))
        }
    }

    static let medicationPrefix = "med-"

    /// One repeating notification per scheduled dose time, for medications with reminders on.
    /// Rebuilt from scratch each time so removed times and turned-off reminders disappear.
    func scheduleMedicationReminders(for medications: [Medication]) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix(NotificationScheduler.medicationPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: pending)
        for m in medications where m.remindersEnabled {
            for minutes in m.scheduleMinutes {
                let content = UNMutableNotificationContent()
                content.title = m.person.map { "\($0.name): \(m.name)" } ?? m.name
                var body = m.dose.isEmpty ? "Time for a dose." : "Time for \(m.dose)."
                if let first = m.instructions.first { body += " \(first.title)." }
                content.body = body
                content.sound = .default
                content.interruptionLevel = m.isCritical ? .timeSensitive : .active
                var comps = DateComponents()
                comps.hour = minutes / 60
                comps.minute = minutes % 60
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                let id = "\(NotificationScheduler.medicationPrefix)\(m.uuid.uuidString)-\(minutes)"
                try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
            }
        }
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    static let checkInIdentifier = "outage-check-in"

    /// During an outage: a repeating nudge to text your people. Local, repeats until stopped.
    func scheduleCheckIn(everyHours hours: Int) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [NotificationScheduler.checkInIdentifier])
        let content = UNMutableNotificationContent()
        content.title = "Check in"
        content.body = "Text your people: where you are, that you're okay, how much battery you have."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(max(1, hours)) * 3600, repeats: true)
        try? await center.add(UNNotificationRequest(identifier: NotificationScheduler.checkInIdentifier, content: content, trigger: trigger))
    }

    func cancelCheckIn() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [NotificationScheduler.checkInIdentifier])
    }

    private func digestBody(itemCount: Int, taskCount: Int, firstItem: String?) -> String {
        var parts: [String] = []
        if itemCount > 0 {
            if let first = firstItem, itemCount == 1 { parts.append("Use \(first) soon.") }
            else { parts.append("\(itemCount) items to use or check.") }
        }
        if taskCount > 0 { parts.append(taskCount == 1 ? "1 equipment task." : "\(taskCount) equipment tasks.") }
        if parts.isEmpty { return "Nothing expiring, nothing due. Enjoy the quiet." }
        return parts.joined(separator: " ")
    }
}
