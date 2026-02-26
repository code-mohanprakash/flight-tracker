import SwiftUI

enum AppTypography {
    static let title = Font.system(size: 28, weight: .bold, design: .default)
    static let heading = Font.system(size: 22, weight: .semibold, design: .default)
    static let subheading = Font.system(size: 17, weight: .medium, design: .default)
    static let body = Font.system(size: 15, weight: .regular, design: .default)
    static let caption = Font.system(size: 13, weight: .regular, design: .default)
    static let small = Font.system(size: 11, weight: .regular, design: .default)

    // Monospace for codes and numbers
    static let flightNumber = Font.system(size: 20, weight: .bold, design: .monospaced)
    static let iataCode = Font.system(size: 15, weight: .semibold, design: .monospaced)
    static let time = Font.system(size: 17, weight: .medium, design: .monospaced)
    static let timeSmall = Font.system(size: 13, weight: .medium, design: .monospaced)
    static let altitude = Font.system(size: 13, weight: .medium, design: .monospaced)
}
