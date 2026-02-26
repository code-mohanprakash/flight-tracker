import SwiftUI

// MARK: - VoiceOver Support

/// Accessibility label builder for flights
enum AccessibilityLabels {
    static func flightLabel(for flight: Flight) -> String {
        var parts: [String] = []
        parts.append("Flight \(flight.displayName)")
        parts.append("from \(flight.departure.displayCode) to \(flight.arrival.displayCode)")
        parts.append("Status: \(flight.status.displayName)")

        if let delay = flight.delayMinutes, delay > 0 {
            parts.append("Delayed \(delay) minutes")
        }
        if let gate = flight.departure.gate {
            parts.append("Gate \(gate)")
        }
        if let terminal = flight.departure.terminal {
            parts.append("Terminal \(terminal)")
        }
        return parts.joined(separator: ". ")
    }

    static func positionLabel(for position: FlightPosition) -> String {
        var parts: [String] = []
        parts.append("Aircraft \(position.cleanCallsign)")
        parts.append("at \(position.altitudeFeet) feet")
        parts.append("heading \(Int(position.trueTrack)) degrees")
        parts.append("speed \(position.speedKnots) knots")
        if position.onGround {
            parts.append("on ground")
        }
        return parts.joined(separator: ". ")
    }

    static func airportLabel(for airport: Airport) -> String {
        "\(airport.fullName), \(airport.city ?? ""), \(airport.country ?? "")"
    }

    static func delayPredictionLabel(for prediction: DelayPrediction) -> String {
        if prediction.predictedDelayMinutes == 0 {
            return "Prediction: Flight expected on time. \(prediction.confidenceLabel) confidence."
        }
        return "Prediction: Estimated \(prediction.predictedDelayMinutes) minute delay. \(prediction.confidenceLabel) confidence. Primary reason: \(prediction.primaryReason.rawValue)."
    }
}

// MARK: - Dynamic Type Support

/// View modifier to ensure minimum touch target size (44x44 per Apple HIG)
struct MinTapTargetModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(minWidth: 44, minHeight: 44)
    }
}

extension View {
    func minTapTarget() -> some View {
        modifier(MinTapTargetModifier())
    }
}

/// View modifier for Dynamic Type scaling with maximum size limit
struct ScaledFontModifier: ViewModifier {
    let baseSize: CGFloat
    let weight: Font.Weight
    let design: Font.Design
    let maxSize: CGFloat

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        let scaledSize = min(scaledValue, maxSize)
        content.font(.system(size: scaledSize, weight: weight, design: design))
    }

    private var scaledValue: CGFloat {
        switch dynamicTypeSize {
        case .xSmall: baseSize * 0.8
        case .small: baseSize * 0.9
        case .medium: baseSize
        case .large: baseSize * 1.1
        case .xLarge: baseSize * 1.2
        case .xxLarge: baseSize * 1.3
        case .xxxLarge: baseSize * 1.4
        case .accessibility1: baseSize * 1.6
        case .accessibility2: baseSize * 1.8
        case .accessibility3: baseSize * 2.0
        case .accessibility4: baseSize * 2.2
        case .accessibility5: baseSize * 2.4
        @unknown default: baseSize
        }
    }
}

extension View {
    func scaledFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default, maxSize: CGFloat = 60) -> some View {
        modifier(ScaledFontModifier(baseSize: size, weight: weight, design: design, maxSize: maxSize))
    }
}

// MARK: - Reduced Motion Support

struct ReducedMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation?

    func body(content: Content) -> some View {
        if reduceMotion {
            content.animation(nil)
        } else {
            content.animation(animation)
        }
    }
}

extension View {
    func respectsReducedMotion(_ animation: Animation? = .default) -> some View {
        modifier(ReducedMotionModifier(animation: animation))
    }
}

// MARK: - High Contrast Support

struct HighContrastModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    let normalOpacity: Double
    let highContrastOpacity: Double

    func body(content: Content) -> some View {
        if contrast == .increased || reduceTransparency {
            content.opacity(highContrastOpacity)
        } else {
            content.opacity(normalOpacity)
        }
    }
}

extension View {
    func adaptiveOpacity(normal: Double = 0.7, highContrast: Double = 1.0) -> some View {
        modifier(HighContrastModifier(normalOpacity: normal, highContrastOpacity: highContrast))
    }
}

// MARK: - Color Blind Safe Palette

/// Alternative status colors for deuteranopia/protanopia users
enum ColorBlindSafeColors {
    static let onTime = Color(hex: "0072B2")      // Blue instead of green
    static let delayed = Color(hex: "E69F00")      // Orange (same)
    static let cancelled = Color(hex: "D55E00")    // Vermillion instead of red
    static let diverted = Color(hex: "CC79A7")     // Pink
    static let landed = Color(hex: "009E73")       // Teal instead of green
    static let scheduled = Color(hex: "8B92A8")    // Gray (same)
}

// MARK: - Accessibility Announcements

enum AccessibilityAnnouncement {
    static func flightStatusChanged(_ flight: Flight) {
        let message = "Flight \(flight.displayName) status changed to \(flight.status.displayName)"
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    static func gateChanged(_ flight: Flight, newGate: String) {
        let message = "Gate changed to \(newGate) for flight \(flight.displayName)"
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    static func searchResults(count: Int) {
        let message = count == 0 ? "No results found" : "\(count) results found"
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    static func mapLoaded(aircraftCount: Int) {
        let message = "\(aircraftCount) aircraft visible on map"
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}
