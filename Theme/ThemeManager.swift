import SwiftUI

class AetherThemeManager: ObservableObject {
    @Published var currentTheme: String {
        didSet { UserDefaults.standard.set(currentTheme, forKey: "aether_theme") }
    }

    let themes = ["midnight", "ocean", "aurora", "crimson", "obsidian"]

    init() {
        self.currentTheme = UserDefaults.standard.string(forKey: "aether_theme") ?? "midnight"
    }

    var cycleName: String {
        switch currentTheme {
        case "midnight": return "Gece Yarısı"
        case "ocean": return "Okyanus"
        case "aurora": return "Aurora"
        case "crimson": return "Kızıl"
        case "obsidian": return "Obsidyen"
        default: return "Gece Yarısı"
        }
    }

    func cycleTheme() {
        if let idx = themes.firstIndex(of: currentTheme) {
            currentTheme = themes[(idx + 1) % themes.count]
        } else {
            currentTheme = themes[0]
        }
    }

    var backgroundGradient: [Color] {
        switch currentTheme {
        case "midnight": return [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.0, green: 0.0, blue: 0.05)]
        case "ocean": return [Color(red: 0.0, green: 0.1, blue: 0.2), Color(red: 0.0, green: 0.05, blue: 0.15)]
        case "aurora": return [Color(red: 0.05, green: 0.1, blue: 0.15), Color(red: 0.0, green: 0.15, blue: 0.1)]
        case "crimson": return [Color(red: 0.15, green: 0.02, blue: 0.05), Color(red: 0.08, green: 0.0, blue: 0.02)]
        case "obsidian": return [Color(red: 0.08, green: 0.08, blue: 0.08), Color(red: 0.02, green: 0.02, blue: 0.02)]
        default: return [Color(red: 0.05, green: 0.05, blue: 0.15), .black]
        }
    }

    var cardBackground: Color { Color.white.opacity(0.06) }

    var accentColor: Color {
        switch currentTheme {
        case "midnight": return Color(red: 0.4, green: 0.5, blue: 1.0)
        case "ocean": return Color(red: 0.2, green: 0.7, blue: 0.9)
        case "aurora": return Color(red: 0.2, green: 0.9, blue: 0.6)
        case "crimson": return Color(red: 0.95, green: 0.3, blue: 0.3)
        case "obsidian": return Color(red: 0.7, green: 0.7, blue: 0.75)
        default: return .blue
        }
    }

    var textPrimary: Color { .white }
    var textSecondary: Color { Color.white.opacity(0.55) }
    var inputBackground: Color { Color.white.opacity(0.08) }
    var userBubbleColor: Color { accentColor.opacity(0.85) }
    var botBubbleColor: Color { Color.white.opacity(0.1) }
}
