import Foundation

enum Configuration {
    static var aviationStackAPIKey: String {
        // In production, load from Secrets.xcconfig or environment
        ProcessInfo.processInfo.environment["AVIATIONSTACK_API_KEY"] ?? "demo_key"
    }

    static var openSkyBaseURL: URL {
        URL(string: "https://opensky-network.org/api")!
    }

    static let positionUpdateInterval: TimeInterval = 10.0
    static let flightRefreshInterval: TimeInterval = 60.0
    static let airportBoardRefreshInterval: TimeInterval = 60.0
    static let searchDebounceInterval: TimeInterval = 0.3
    static let maxVisibleAircraft: Int = 500
    static let cacheTTL: TimeInterval = 300 // 5 minutes
}
