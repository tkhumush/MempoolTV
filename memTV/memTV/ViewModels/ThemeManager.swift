import SwiftUI

enum Theme: String, CaseIterable {
    case dark = "dark"
    case light = "light"

    var name: String {
        switch self {
        case .dark:
            return "Dark"
        case .light:
            return "Light"
        }
    }
}

class ThemeManager: ObservableObject {
    @Published var currentTheme: Theme = .dark

    init() {
        currentTheme = .dark
    }

    func toggleTheme() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = currentTheme == .dark ? .light : .dark
        }
    }

    var backgroundColor: Color {
        switch currentTheme {
        case .dark:
            return Color(red: 28/255, green: 28/255, blue: 28/255)
        case .light:
            return Color(red: 248/255, green: 248/255, blue: 248/255)
        }
    }

    var contentViewBackgroundColor: Color {
        switch currentTheme {
        case .dark:
            return Color(red: 64/255, green: 64/255, blue: 64/255) // Dark gray
        case .light:
            return Color(red: 51/255, green: 153/255, blue: 204/255) // Original blue (#3399CC)
        }
    }

    var primaryTextColor: Color {
        switch currentTheme {
        case .dark:
            return .white
        case .light:
            return .black
        }
    }

    var secondaryTextColor: Color {
        switch currentTheme {
        case .dark:
            return .gray
        case .light:
            return Color.gray
        }
    }

    var cardBackgroundColor: Color {
        switch currentTheme {
        case .dark:
            return Color.black.opacity(0.3)
        case .light:
            return Color.white.opacity(0.8)
        }
    }

    var cardBorderColor: Color {
        switch currentTheme {
        case .dark:
            return Color.gray.opacity(0.2)
        case .light:
            return Color.gray.opacity(0.3)
        }
    }

    var errorColor: Color {
        return .red
    }

    var successColor: Color {
        return .green
    }

    var accentColor: Color {
        return .blue
    }

    var warningColor: Color {
        return .yellow
    }
}