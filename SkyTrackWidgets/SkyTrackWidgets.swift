import WidgetKit
import SwiftUI

// MARK: - Widget Bundle

@main
struct SkyTrackWidgetBundle: WidgetBundle {
    var body: some Widget {
        SmallFlightWidget()
        MediumFlightWidget()
        LargeFlightWidget()
        LockScreenFlightWidget()
    }
}

// MARK: - Shared Timeline Provider

struct FlightEntry: TimelineEntry {
    let date: Date
    let flight: WidgetFlight?
    let configuration: ConfigurationAppIntent?
}

struct WidgetFlight: Codable {
    let flightNumber: String
    let departureCode: String
    let arrivalCode: String
    let departureTime: Date?
    let arrivalTime: Date?
    let status: String
    let gate: String?
    let terminal: String?
    let delayMinutes: Int?
    let progress: Double?

    var isDelayed: Bool {
        (delayMinutes ?? 0) > 5
    }

    var statusColor: String {
        switch status {
        case "active": return "blue"
        case "landed": return "green"
        case "cancelled": return "red"
        case "diverted": return "purple"
        default: return "gray"
        }
    }

    var countdownText: String {
        guard let depTime = departureTime else { return "--" }
        let interval = depTime.timeIntervalSince(Date())
        if interval <= 0 { return "Now" }
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }

    static let placeholder = WidgetFlight(
        flightNumber: "UA123",
        departureCode: "SFO",
        arrivalCode: "JFK",
        departureTime: Date().addingTimeInterval(3600),
        arrivalTime: Date().addingTimeInterval(21600),
        status: "scheduled",
        gate: "G92",
        terminal: "3",
        delayMinutes: nil,
        progress: nil
    )
}

struct ConfigurationAppIntent: Codable {
    var flightNumber: String?
}

// MARK: - Shared Data

struct FlightTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> FlightEntry {
        FlightEntry(date: Date(), flight: .placeholder, configuration: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (FlightEntry) -> Void) {
        let entry = FlightEntry(date: Date(), flight: loadNextFlight(), configuration: nil)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FlightEntry>) -> Void) {
        let flight = loadNextFlight()
        let entry = FlightEntry(date: Date(), flight: flight, configuration: nil)
        let nextUpdate = Date().addingTimeInterval(15 * 60) // 15 min refresh
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadNextFlight() -> WidgetFlight? {
        // Read from shared UserDefaults (app group)
        guard let data = UserDefaults(suiteName: "group.com.skytrack.app")?
            .data(forKey: "nextFlight"),
              let flight = try? JSONDecoder().decode(WidgetFlight.self, from: data) else {
            return nil
        }
        return flight
    }
}
