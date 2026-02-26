import ActivityKit
import Foundation

struct FlightActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic state — updated in real-time
        var status: String              // "boarding", "departed", "in_air", "approaching", "landed"
        var departureTime: Date?
        var arrivalTime: Date?
        var gate: String?
        var progress: Double            // 0.0 - 1.0
        var altitude: Int?              // feet
        var speed: Int?                 // knots
        var delayMinutes: Int?
        var etaCountdown: TimeInterval? // seconds until arrival

        var isDelayed: Bool { (delayMinutes ?? 0) > 5 }

        var statusDisplay: String {
            switch status {
            case "boarding": return "Boarding"
            case "departed": return "Departed"
            case "in_air": return "In Air"
            case "approaching": return "Approaching"
            case "landed": return "Landed"
            default: return "Tracking"
            }
        }

        var statusEmoji: String {
            switch status {
            case "boarding": return "🚶"
            case "departed": return "🛫"
            case "in_air": return "✈️"
            case "approaching": return "🛬"
            case "landed": return "✅"
            default: return "📡"
            }
        }
    }

    // Static attributes — set once when activity starts
    var flightNumber: String
    var airlineCode: String
    var departureCode: String
    var arrivalCode: String
    var departureAirportName: String
    var arrivalAirportName: String
    var scheduledDeparture: Date
    var scheduledArrival: Date
}
