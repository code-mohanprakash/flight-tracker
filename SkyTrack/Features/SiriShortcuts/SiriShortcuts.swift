import Foundation
import Intents
import AppIntents
import os

// MARK: - App Intents (iOS 16+)

/// "Check flight status" Siri shortcut
struct CheckFlightStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Flight Status"
    static var description: IntentDescription = "Get the current status of a flight"
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Flight Number")
    var flightNumber: String

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let status = await fetchFlightStatus(flightNumber)

        let dialog: IntentDialog
        switch status {
        case let .found(flight):
            dialog = "\(flight.displayName) is \(flight.statusText). Route: \(flight.route). \(flight.timeInfo)"
        case .notFound:
            dialog = "I couldn't find flight \(flightNumber). Please check the flight number."
        case .error:
            dialog = "Sorry, I had trouble checking that flight. Please try again."
        }

        return .result(dialog: dialog) {
            FlightStatusSnippetView(flightNumber: flightNumber, status: status)
        }
    }

    private func fetchFlightStatus(_ number: String) async -> FlightLookupResult {
        // Read from cached data in shared container
        guard let defaults = UserDefaults(suiteName: "group.com.skytrack.shared"),
              let data = defaults.data(forKey: "cached_flights"),
              let flights = try? JSONDecoder().decode([SiriFlightInfo].self, from: data) else {
            return .error
        }

        if let flight = flights.first(where: {
            $0.flightNumber.lowercased() == number.lowercased() ||
            $0.displayName.lowercased() == number.lowercased()
        }) {
            return .found(flight)
        }

        return .notFound
    }
}

/// "Track a flight" Siri shortcut
struct TrackFlightIntent: AppIntent {
    static var title: LocalizedStringResource = "Track Flight"
    static var description: IntentDescription = "Start tracking a flight"
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Flight Number")
    var flightNumber: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        return .result(dialog: "Opening SkyTrack to track \(flightNumber)")
    }
}

/// "What flights are overhead?" Siri shortcut
struct NearbyFlightsIntent: AppIntent {
    static var title: LocalizedStringResource = "Flights Overhead"
    static var description: IntentDescription = "See what flights are above you right now"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        return .result(dialog: "Opening SkyTrack AR view to see nearby flights")
    }
}

/// "My next flight" shortcut
struct NextFlightIntent: AppIntent {
    static var title: LocalizedStringResource = "My Next Flight"
    static var description: IntentDescription = "Get info about your upcoming flight"
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let defaults = UserDefaults(suiteName: "group.com.skytrack.shared"),
              let data = defaults.data(forKey: "cached_flights"),
              let flights = try? JSONDecoder().decode([SiriFlightInfo].self, from: data) else {
            return .result(dialog: "No upcoming flights found. Add flights in SkyTrack.")
        }

        let upcoming = flights
            .filter { $0.departureDate > Date() }
            .sorted { $0.departureDate < $1.departureDate }

        guard let next = upcoming.first else {
            return .result(dialog: "No upcoming flights found. Add flights in SkyTrack.")
        }

        return .result(dialog: "Your next flight is \(next.displayName) from \(next.origin) to \(next.destination), departing \(next.formattedDeparture).")
    }
}

// MARK: - App Shortcuts Provider

struct SkyTrackShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CheckFlightStatusIntent(),
            phrases: [
                "Check flight status in \(.applicationName)",
                "What's the status of my flight in \(.applicationName)",
                "Is my flight on time with \(.applicationName)",
            ],
            shortTitle: "Flight Status",
            systemImageName: "airplane"
        )
        AppShortcut(
            intent: NextFlightIntent(),
            phrases: [
                "My next flight in \(.applicationName)",
                "When is my flight with \(.applicationName)",
                "Show my upcoming flight in \(.applicationName)",
            ],
            shortTitle: "Next Flight",
            systemImageName: "calendar"
        )
        AppShortcut(
            intent: NearbyFlightsIntent(),
            phrases: [
                "What flights are overhead with \(.applicationName)",
                "Show flights above me in \(.applicationName)",
                "Identify that plane with \(.applicationName)",
            ],
            shortTitle: "Flights Overhead",
            systemImageName: "camera.viewfinder"
        )
    }
}

// MARK: - Models

enum FlightLookupResult {
    case found(SiriFlightInfo)
    case notFound
    case error
}

struct SiriFlightInfo: Codable {
    let flightNumber: String
    let displayName: String
    let origin: String
    let destination: String
    let statusText: String
    let route: String
    let timeInfo: String
    let departureDate: Date
    let formattedDeparture: String
}

// MARK: - Snippet View

import SwiftUI

struct FlightStatusSnippetView: View {
    let flightNumber: String
    let status: FlightLookupResult

    var body: some View {
        switch status {
        case .found(let flight):
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(flight.displayName)
                        .font(.headline.monospaced())
                    Spacer()
                    Text(flight.statusText)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.15))
                        .clipShape(Capsule())
                }
                Text(flight.route)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(flight.timeInfo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        case .notFound:
            Text("Flight \(flightNumber) not found")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding()
        case .error:
            Text("Unable to check flight status")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding()
        }
    }
}
