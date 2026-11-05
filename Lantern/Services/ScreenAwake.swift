import UIKit

/// Keeps the screen on while any tool that needs it is open. Reference counted, so one screen
/// leaving does not clear another's hold.
@MainActor
enum ScreenAwake {
    private static var holds = 0
    static func hold() { holds += 1; UIApplication.shared.isIdleTimerDisabled = true }
    static func release() { holds = max(0, holds - 1); UIApplication.shared.isIdleTimerDisabled = holds > 0 }
}
