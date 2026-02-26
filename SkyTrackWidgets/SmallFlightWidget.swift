import WidgetKit
import SwiftUI

struct SmallFlightWidget: Widget {
    let kind = "SmallFlightWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FlightTimelineProvider()) { entry in
            SmallFlightWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Next Flight")
        .description("Countdown to your next flight with status.")
        .supportedFamilies([.systemSmall])
    }
}

struct SmallFlightWidgetView: View {
    let entry: FlightEntry

    var body: some View {
        if let flight = entry.flight {
            VStack(alignment: .leading, spacing: 6) {
                // Flight Number & Status
                HStack {
                    Text(flight.flightNumber)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(.primary)
                    Spacer()
                    Circle()
                        .fill(statusColor(flight))
                        .frame(width: 8, height: 8)
                }

                Spacer()

                // Route
                HStack(spacing: 4) {
                    Text(flight.departureCode)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Text(flight.arrivalCode)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                }

                // Countdown or Gate
                if let gate = flight.gate {
                    Text("Gate \(gate)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                // Countdown
                Text(flight.countdownText)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(flight.isDelayed ? .orange : .primary)

                if flight.isDelayed, let delay = flight.delayMinutes {
                    Text("+\(delay) min")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.orange)
                }
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "airplane.circle")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
                Text("No upcoming flights")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func statusColor(_ flight: WidgetFlight) -> Color {
        switch flight.status {
        case "active": return .blue
        case "landed": return .green
        case "cancelled": return .red
        case "diverted": return .purple
        default:
            return flight.isDelayed ? .orange : .green
        }
    }
}

#Preview(as: .systemSmall) {
    SmallFlightWidget()
} timeline: {
    FlightEntry(date: Date(), flight: .placeholder, configuration: nil)
    FlightEntry(date: Date(), flight: nil, configuration: nil)
}
