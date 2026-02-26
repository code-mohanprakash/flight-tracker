import WidgetKit
import SwiftUI

struct LargeFlightWidget: Widget {
    let kind = "LargeFlightWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MultiFlightTimelineProvider()) { entry in
            LargeFlightWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Upcoming Flights")
        .description("Your next 3 flights at a glance.")
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - Multi-Flight Provider

struct MultiFlightEntry: TimelineEntry {
    let date: Date
    let flights: [WidgetFlight]
}

struct MultiFlightTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> MultiFlightEntry {
        MultiFlightEntry(date: Date(), flights: [.placeholder])
    }

    func getSnapshot(in context: Context, completion: @escaping (MultiFlightEntry) -> Void) {
        completion(MultiFlightEntry(date: Date(), flights: loadFlights()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MultiFlightEntry>) -> Void) {
        let entry = MultiFlightEntry(date: Date(), flights: loadFlights())
        let nextUpdate = Date().addingTimeInterval(15 * 60)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadFlights() -> [WidgetFlight] {
        guard let data = UserDefaults(suiteName: "group.com.skytrack.app")?
            .data(forKey: "upcomingFlights"),
              let flights = try? JSONDecoder().decode([WidgetFlight].self, from: data) else {
            return []
        }
        return Array(flights.prefix(3))
    }
}

// MARK: - Large Widget View

struct LargeFlightWidgetView: View {
    let entry: MultiFlightEntry

    var body: some View {
        if entry.flights.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "airplane.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("No upcoming flights")
                    .font(.system(size: 16, weight: .medium))
                Text("Add flights in SkyTrack to see them here")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text("UPCOMING FLIGHTS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .tracking(1)

                ForEach(Array(entry.flights.enumerated()), id: \.offset) { _, flight in
                    flightRow(flight)
                    if flight.flightNumber != entry.flights.last?.flightNumber {
                        Divider().background(Color.secondary.opacity(0.3))
                    }
                }

                Spacer(minLength: 0)
            }
        }
    }

    private func flightRow(_ flight: WidgetFlight) -> some View {
        VStack(spacing: 6) {
            // Header
            HStack {
                Text(flight.flightNumber)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                Spacer()
                statusPill(flight)
            }

            // Route
            HStack {
                routeColumn(code: flight.departureCode, time: flight.departureTime, alignment: .leading)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Spacer()
                routeColumn(code: flight.arrivalCode, time: flight.arrivalTime, alignment: .trailing)
            }

            // Gate + delay
            HStack {
                if let gate = flight.gate {
                    Text("Gate \(gate)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if flight.isDelayed, let delay = flight.delayMinutes {
                    Text("+\(delay) min")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func routeColumn(code: String, time: Date?, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(code)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
            if let time {
                Text(time.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func statusPill(_ flight: WidgetFlight) -> some View {
        let text: String
        let color: Color
        switch flight.status {
        case "active": text = "In Air"; color = .blue
        case "landed": text = "Landed"; color = .green
        case "cancelled": text = "Cancelled"; color = .red
        default: text = flight.countdownText; color = flight.isDelayed ? .orange : .green
        }

        return Text(text)
            .font(.system(size: 10, weight: .semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

#Preview(as: .systemLarge) {
    LargeFlightWidget()
} timeline: {
    MultiFlightEntry(date: Date(), flights: [
        WidgetFlight(flightNumber: "UA123", departureCode: "SFO", arrivalCode: "JFK",
                     departureTime: Date().addingTimeInterval(3600), arrivalTime: Date().addingTimeInterval(21600),
                     status: "scheduled", gate: "G92", terminal: "3", delayMinutes: 15, progress: nil),
        WidgetFlight(flightNumber: "BA456", departureCode: "JFK", arrivalCode: "LHR",
                     departureTime: Date().addingTimeInterval(86400), arrivalTime: Date().addingTimeInterval(108000),
                     status: "scheduled", gate: nil, terminal: "7", delayMinutes: nil, progress: nil),
    ])
}
