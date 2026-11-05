import SwiftUI

extension Color {
    /// The app's accent as a named asset. Used instead of `Color.ink`, which can resolve to an
    /// enclosing `.tint` (the amber tab tint) on some iOS versions. Amber is never a button.
    static let ink = Color("AccentColor")
}
