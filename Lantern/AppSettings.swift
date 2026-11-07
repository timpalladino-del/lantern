import Foundation

/// UserDefaults keys. All local.
enum AppSettings {
    static let notificationsEnabled = "settings.notificationsEnabled"
    static let digestWeekday = "settings.digestWeekday"   // 1 = Sunday
    static let digestHour = "settings.digestHour"
    /// Supply categories that get no per-item reminder, as raw values joined by commas. Empty means all on.
    static let reminderMutedCategories = "settings.reminderMutedCategories"
    static let strobeWarningSeen = "settings.strobeWarningSeen"
    static let onlineLookupEnabled = "settings.onlineLookupEnabled"
    static let hasSeenWelcome = "settings.hasSeenWelcome"
    static let checkInHours = "settings.checkInHours"
    static let checkInEnabled = "settings.checkInEnabled"
    /// Set on a family member's phone after they answer an invitation: which household they belong to.
    static let memberOfHouseholdToken = "settings.memberOfHouseholdToken"
    static let memberOfHouseholdName = "settings.memberOfHouseholdName"
}
