import SwiftUI

/// One dark-room palette for every screen, card and focus surface.
@MainActor
final class ThemeManager: ObservableObject {
    var backgroundColor: Color { ObservatoryStyle.canvas }
    var contentViewBackgroundColor: Color { ObservatoryStyle.canvas }
    var primaryTextColor: Color { ObservatoryStyle.text }
    var secondaryTextColor: Color { ObservatoryStyle.secondary }
    var cardBackgroundColor: Color { ObservatoryStyle.card }
    var cardBorderColor: Color { ObservatoryStyle.secondary.opacity(0.15) }
    var errorColor: Color { ObservatoryStyle.unavailable }
    var successColor: Color { ObservatoryStyle.teal }
    var accentColor: Color { ObservatoryStyle.orange }
    var warningColor: Color { ObservatoryStyle.stale }
}
