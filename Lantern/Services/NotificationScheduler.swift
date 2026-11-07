import Foundation
import UserNotifications

/// Local notifications only. Scheduled by iOS, so they fire with no network and no server.
/// One weekly digest, plus one reminder the morning something is about to expire (same-day items fold together).
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
                    mutedCategories: Set<SupplyCategory> = NotificationScheduler.mutedCategories(),
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

        // Per-item reminders for every category the user left on. Everything due the same morning
        // folds into one notification, so a big pantry never turns into a stream of pings.
        var byDay: [Date: [SupplyItem]] = [:]
        for item in items where item.quantity > 0 && !mutedCategories.contains(item.category) {
            guard let exp = item.expirationDate, exp > now else { continue }
            let lead = NotificationScheduler.leadDays(for: item.category)
            guard let fire = Calendar.current.date(byAdding: .day, value: -lead, to: exp), fire > now else { continue }
            byDay[Calendar.current.startOfDay(for: fire), default: []].append(item)
        }
        for (day, group) in byDay.sorted(by: { $0.key < $1.key }).prefix(NotificationScheduler.maxReminderDays) {
            let sorted = group.sorted { ($0.expirationDate ?? now) < ($1.expirationDate ?? now) }
            let text = NotificationScheduler.reminderText(names: sorted.map(\.name),
                                                          categories: sorted.map(\.category),
                                                          firstExpiry: sorted.first?.expirationDate)
            let content = UNMutableNotificationContent()
            content.title = text.title
            content.body = text.body
            content.sound = .default
            var at = Calendar.current.dateComponents([.year, .month, .day], from: day)
            at.hour = digestHour
            let t = UNCalendarNotificationTrigger(dateMatching: at, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: "items-\(Int(day.timeIntervalSince1970))", content: content, trigger: t))
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

    // MARK: Per-item reminder rules

    /// iOS keeps about 64 pending notifications. The digest, dose reminders and equipment checks share
    /// that budget, so item reminders stop at this many distinct mornings.
    nonisolated static let maxReminderDays = 40

    /// How far ahead the reminder lands. Water is a rotation, not a cliff, so a week is plenty.
    nonisolated static func leadDays(for category: SupplyCategory) -> Int {
        switch category {
        case .water: return 7
        default: return 14
        }
    }

    /// Categories the user switched off in Settings. Stored as raw values joined by commas.
    nonisolated static func mutedCategories(defaults: UserDefaults = .standard) -> Set<SupplyCategory> {
        let raw = defaults.string(forKey: AppSettings.reminderMutedCategories) ?? ""
        return Set(raw.split(separator: ",").compactMap { SupplyCategory(rawValue: String($0)) })
    }

    nonisolated static func setMutedCategories(_ set: Set<SupplyCategory>, defaults: UserDefaults = .standard) {
        defaults.set(set.map(\.rawValue).sorted().joined(separator: ","), forKey: AppSettings.reminderMutedCategories)
    }

    /// One notification's words for everything due the same morning.
    nonisolated static func reminderText(names: [String], categories: [SupplyCategory], firstExpiry: Date?) -> (title: String, body: String) {
        let when = firstExpiry.map { $0.formatted(date: .abbreviated, time: .omitted) }
        if names.count == 1, let name = names.first {
            if categories.first == .water {
                return ("Time to rotate water", "\(name) was filled or bought a while ago. Refill or replace it this week.")
            }
            return ("\(name) is due soon", when.map { "Expires \($0). Check it and restock if needed." } ?? "Check it and restock if needed.")
        }
        if categories.allSatisfy({ $0 == .water }) {
            return ("Time to rotate water", "\(names.count) containers are due. Refill or replace them this week.")
        }
        let shown = names.prefix(3).joined(separator: ", ")
        let rest = names.count - min(3, names.count)
        let list = rest > 0 ? "\(shown) and \(rest) more" : shown
        return ("\(names.count) supplies due soon", "\(list). Use them first or restock.")
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
    func scheduleCheckIn(everyHours hours: Int, contactNames: [String] = []) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [NotificationScheduler.checkInIdentifier])
        let content = UNMutableNotificationContent()
        content.title = "Check in"
        let who = contactNames.isEmpty ? "your people" : contactNames.joined(separator: " and ")
        content.body = "Text \(who): where you are, that you're okay, how much battery you have."
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
