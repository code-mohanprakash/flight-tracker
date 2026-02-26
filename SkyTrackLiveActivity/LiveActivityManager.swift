import ActivityKit
import Foundation
import os

/// Manages the lifecycle of Live Activities for flight tracking.
@Observable
final class LiveActivityManager {
    var currentActivity: Activity<FlightActivityAttributes>?
    var isActivityRunning: Bool { currentActivity != nil }

    private static let logger = Logger(subsystem: "com.skytrack.app", category: "live-activity")

    // MARK: - Start Activity

    func startTracking(flight: Flight) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            Self.logger.warning("Live Activities not enabled")
            return
        }

        let attributes = FlightActivityAttributes(
            flightNumber: flight.displayName,
            airlineCode: flight.airline?.displayCode ?? "",
            departureCode: flight.departure.displayCode,
            arrivalCode: flight.arrival.displayCode,
            departureAirportName: flight.departure.airportName ?? "",
            arrivalAirportName: flight.arrival.airportName ?? "",
            scheduledDeparture: flight.departure.scheduledTime ?? Date(),
            scheduledArrival: flight.arrival.scheduledTime ?? Date()
        )

        let initialState = createContentState(from: flight)

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: Date().addingTimeInterval(3600)),
                pushType: nil
            )
            currentActivity = activity
            Self.logger.info("Started Live Activity for \(flight.displayName)")
        } catch {
            Self.logger.error("Failed to start Live Activity: \(error)")
        }
    }

    // MARK: - Update Activity

    func update(with flight: Flight) async {
        guard let activity = currentActivity else { return }

        let state = createContentState(from: flight)
        let content = ActivityContent(
            state: state,
            staleDate: Date().addingTimeInterval(3600)
        )

        await activity.update(content)
        Self.logger.info("Updated Live Activity for \(flight.displayName)")
    }

    // MARK: - End Activity

    func stopTracking(flight: Flight? = nil) async {
        guard let activity = currentActivity else { return }

        let finalState: FlightActivityAttributes.ContentState
        if let flight {
            finalState = createContentState(from: flight)
        } else {
            finalState = FlightActivityAttributes.ContentState(
                status: "landed",
                departureTime: nil,
                arrivalTime: nil,
                gate: nil,
                progress: 1.0,
                altitude: nil,
                speed: nil,
                delayMinutes: nil,
                etaCountdown: nil
            )
        }

        let content = ActivityContent(state: finalState, staleDate: nil)
        await activity.end(content, dismissalPolicy: .after(.now + 3600)) // Keep for 1hr after landing

        currentActivity = nil
        Self.logger.info("Ended Live Activity")
    }

    // MARK: - State Creation

    private func createContentState(from flight: Flight) -> FlightActivityAttributes.ContentState {
        let status: String
        switch flight.status {
        case .scheduled:
            if let depTime = flight.departure.estimatedTime ?? flight.departure.scheduledTime,
               Date().timeIntervalSince(depTime) > -1800 {
                status = "boarding"
            } else {
                status = "scheduled"
            }
        case .active:
            if let arrTime = flight.arrival.estimatedTime ?? flight.arrival.scheduledTime,
               arrTime.timeIntervalSinceNow < 1800 {
                status = "approaching"
            } else {
                status = "in_air"
            }
        case .landed:
            status = "landed"
        default:
            status = flight.status.rawValue
        }

        let etaCountdown: TimeInterval?
        if let arrTime = flight.arrival.estimatedTime ?? flight.arrival.scheduledTime {
            etaCountdown = max(0, arrTime.timeIntervalSinceNow)
        } else {
            etaCountdown = nil
        }

        return FlightActivityAttributes.ContentState(
            status: status,
            departureTime: flight.departure.actualTime ?? flight.departure.estimatedTime,
            arrivalTime: flight.arrival.estimatedTime ?? flight.arrival.scheduledTime,
            gate: flight.departure.gate,
            progress: flight.progress ?? 0,
            altitude: flight.liveData?.altitudeFeet,
            speed: flight.liveData?.speedKnots,
            delayMinutes: flight.delayMinutes,
            etaCountdown: etaCountdown
        )
    }
}
