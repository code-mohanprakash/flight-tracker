import SwiftUI

enum AppColors {
    // MARK: - Backgrounds
    static let background = Color(hex: "0A0E1A")
    static let surface = Color(hex: "141929")
    static let surfaceElevated = Color(hex: "1E2338")
    static let surfacePressed = Color(hex: "252A42")

    // MARK: - Primary
    static let primary = Color(hex: "4A9EFF")
    static let primaryDim = Color(hex: "4A9EFF").opacity(0.15)

    // MARK: - Status Colors
    static let onTime = Color(hex: "34D058")
    static let delayed = Color(hex: "FFB020")
    static let cancelled = Color(hex: "F85149")
    static let diverted = Color(hex: "A371F7")
    static let landed = Color(hex: "34D058")
    static let scheduled = Color(hex: "8B92A8")
    static let boarding = Color(hex: "4A9EFF")
    static let inAir = Color(hex: "4A9EFF")

    // MARK: - Text
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "8B92A8")
    static let textTertiary = Color(hex: "565E75")

    // MARK: - Accent
    static let accent = Color(hex: "A78BFA")

    // MARK: - Semantic
    static let separator = Color.white.opacity(0.08)
    static let overlay = Color.black.opacity(0.5)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
