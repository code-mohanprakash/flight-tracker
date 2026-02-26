import Foundation

enum Configuration {
    // MARK: - Free API Endpoints (No API Keys Required)

    /// Primary: ADSB.lol — Fully open source, no rate limits, ODbL licensed
    static var adsbLolBaseURL: URL {
        URL(string: "https://api.adsb.lol/v2")!
    }

    /// Fallback: ADSB.One — 1 req/sec, no API key needed
    static var adsbOneBaseURL: URL {
        URL(string: "https://api.adsb.one/v2")!
    }

    /// Last resort: OpenSky Network — 4,000 credits/day
    static var openSkyBaseURL: URL {
        URL(string: "https://opensky-network.org/api")!
    }

    // MARK: - Timing

    static let positionUpdateInterval: TimeInterval = 10.0
    static let flightRefreshInterval: TimeInterval = 60.0
    static let airportBoardRefreshInterval: TimeInterval = 60.0
    static let searchDebounceInterval: TimeInterval = 0.3

    // MARK: - Limits

    static let maxVisibleAircraft: Int = 500
    static let cacheTTL: TimeInterval = 300 // 5 minutes

    // MARK: - Data Sources Info

    static let dataSources = """
    ADSB.lol — Primary (no rate limits, fully open source)
    ADSB.One — Fallback (1 req/sec, no key)
    OpenSky Network — Last resort (4,000 credits/day)
    Local Database — Airport & airline lookups (instant, offline)
    """
}
