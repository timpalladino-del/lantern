import SwiftUI

extension Color {
    /// The app's accent as a named asset. Used instead of `Color.ink`, which can resolve to an
    /// enclosing `.tint` (the amber tab tint) on some iOS versions. Amber is never a button.
    static let ink = Color("AccentColor")
    /// Playing-card red. Plain red, so Signal stays reserved for expired medicine.
    static let cardRed = Color(red: 0.78, green: 0.16, blue: 0.16)
}
