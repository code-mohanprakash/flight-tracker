import Foundation

/// App Store metadata configuration for ASO (App Store Optimization).
/// This file serves as the single source of truth for all store-facing copy.
enum AppStoreMetadata {
    // MARK: - App Identity

    static let appName = "SkyTrack — Flight Tracker"
    static let subtitle = "Live Flights, Delays & AR View"
    static let bundleID = "com.skytrack.app"
    static let appCategory = "Travel"
    static let secondaryCategory = "Navigation"
    static let ageRating = "4+"
    static let price = "Free"

    // MARK: - Description

    static let description = """
    SkyTrack is the ultimate free flight tracker. Track flights in real-time, \
    predict delays before airlines announce them, identify planes overhead with AR, \
    and never miss a gate change again.

    REAL-TIME FLIGHT MAP
    • Live map with 60,000+ flights worldwide
    • Aircraft colored by altitude with smooth animations
    • Tap any plane to see full flight details instantly
    • Advanced filters: airline, altitude, speed, aircraft type

    SMART DELAY PREDICTIONS
    • AI-powered predictions up to 6 hours before airlines announce
    • Tracks inbound aircraft — "Where's My Plane" feature
    • Analyzes 5 factors: late aircraft, history, time-of-day, congestion, cascade
    • Confidence scoring so you know how reliable the prediction is

    AR SKY VIEW
    • Point your camera at the sky to identify flights overhead
    • See flight number, altitude, speed, and heading in AR
    • Compass overlay with bearing to each aircraft

    COMPLETE FLIGHT DETAILS
    • Route progress with animated airplane indicator
    • Gate, terminal, baggage claim — with change alerts
    • Live altitude, speed, heading, vertical rate
    • Aircraft type, registration, and age

    SMART NOTIFICATIONS
    • Gate changes, delays, cancellations, diversions
    • Boarding reminders 30 minutes before departure
    • Baggage carousel alerts on landing
    • Predictive delay warnings before the airline knows

    WIDGETS & LIVE ACTIVITIES
    • Home screen widgets: small, medium, and large
    • Lock screen widgets and complications
    • Dynamic Island with real-time flight progress
    • Apple Watch companion app

    MORE FEATURES
    • 3D flight visualization with cockpit camera mode
    • Travel statistics dashboard with year-in-review
    • Friends tracking with pickup countdown
    • iMessage flight card sharing
    • Calendar import for automatic flight detection
    • Email booking parser
    • CarPlay dashboard
    • Siri Shortcuts
    • Spotlight search integration
    • Full VoiceOver and Dynamic Type support

    100% FREE — NO SUBSCRIPTIONS — NO ADS
    Every feature is free. If you love SkyTrack, you can leave an optional tip \
    to support development.

    Data powered by OpenSky Network and AviationStack.
    """

    // MARK: - Keywords (100 char limit)

    static let keywords = "flight tracker,live flights,plane tracker,delay prediction,flight status,AR plane,airport,radar"

    // MARK: - What's New (per version)

    static let whatsNew = """
    Welcome to SkyTrack! This initial release includes:
    • Real-time flight map with 60,000+ flights
    • Smart delay predictions with AI
    • AR Sky View for identifying overhead flights
    • 3D flight visualization
    • Widgets, Live Activities, and Apple Watch app
    • Travel statistics and year-in-review
    • Friends tracking and sharing
    • CarPlay, Siri Shortcuts, and Spotlight
    • Full accessibility support
    """

    // MARK: - Screenshot Captions

    static let screenshotCaptions: [String] = [
        "Track 60,000+ live flights worldwide",
        "Predict delays before airlines announce them",
        "Identify planes overhead with AR",
        "Complete flight details at a glance",
        "Dynamic Island and lock screen updates",
        "Beautiful travel statistics dashboard",
    ]

    // MARK: - Promotional Text (170 chars, can change without review)

    static let promotionalText = "The most powerful flight tracker — now with AI delay predictions and AR sky view. 100% free, no ads, no subscriptions."

    // MARK: - Support URL

    static let supportURL = "https://skytrack.app/support"
    static let privacyPolicyURL = "https://skytrack.app/privacy"
    static let marketingURL = "https://skytrack.app"

    // MARK: - Screenshot Configuration

    struct ScreenshotConfig {
        let device: String
        let width: Int
        let height: Int

        static let iPhone15ProMax = ScreenshotConfig(device: "iPhone 15 Pro Max", width: 1290, height: 2796)
        static let iPhone15Pro = ScreenshotConfig(device: "iPhone 15 Pro", width: 1179, height: 2556)
        static let iPadPro129 = ScreenshotConfig(device: "iPad Pro 12.9\"", width: 2048, height: 2732)
        static let iPadPro11 = ScreenshotConfig(device: "iPad Pro 11\"", width: 1668, height: 2388)

        static let required: [ScreenshotConfig] = [
            iPhone15ProMax, iPhone15Pro, iPadPro129, iPadPro11
        ]
    }
}
