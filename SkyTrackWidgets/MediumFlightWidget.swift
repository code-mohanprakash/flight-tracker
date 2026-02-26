import WidgetKit
import SwiftUI

struct MediumFlightWidget: Widget {
    let kind = "MediumFlightWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FlightTimelineProvider()) { entry in
            MediumFlightWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Flight Progress")
        .description("Active flight progress with ETA and gate info.")
        .supportedFamilies([.systemMedium])
    }
}

struct MediumFlightWidgetView: View {
    let entry: FlightEntry

    var body: some View {
        if let flight = entry.flight {
            VStack(spacing: 8) {
                // Header: Flight number + status
                HStack {
                    Text(flight.flightNumber)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                    Spacer()
                    statusBadge(flight)
                }

                // Route with progress
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(flight.departureCode)
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                        if let time = flight.departureTime {
                            Text(time.formatted(date: .omitted, time: .shortened))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(flight.isDelayed ? .orange : .secondary)
                        }
                    }

                    Spacer()

                    // Progress bar
                    progressBar(progress: flight.progress)
                        .frame(maxWidth: 120)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(flight.arrivalCode)
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                        if let time = flight.arrivalTime {
                            Text(time.formatted(date: .omitted, time: .shortened))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Footer: Gate + Delay info
                HStack {
                    if let gate = flight.gate {
                        Label("Gate \(gate)", systemImage: "door.left.hand.open")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    if let terminal = flight.terminal {
                        Label("T\(terminal)", systemImage: "building.2")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if flight.isDelayed, let delay = flight.delayMinutes {
                        Text("Delayed \(delay) min")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.orange)
                    }
                }
            }
        } else {
            HStack(spacing: 12) {
                Image(systemName: "airplane.circle")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("No upcoming flights")
                        .font(.system(size: 14, weight: .medium))
                    Text("Add a flight in SkyTrack to see it here")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func statusBadge(_ flight: WidgetFlight) -> some View {
        let text: String
        let color: Color
        switch flight.status {
        case "active":
            text = "In Air"
            color = .blue
        case "landed":
            text = "Landed"
            color = .green
        case "cancelled":
            text = "Cancelled"
            color = .red
        default:
            text = flight.countdownText
            color = flight.isDelayed ? .orange : .green
        }

        return Text(text)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func progressBar(progress: Double?) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 3)

                if let progress {
                    Capsule()
                        .fill(Color.blue)
                        .frame(width: geo.size.width * progress, height: 3)

                    if progress > 0 && progress < 1 {
                        Image(systemName: "airplane")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.blue)
                            .offset(x: geo.size.width * progress - 6)
                    }
                }

                Circle().fill(Color.secondary).frame(width: 6, height: 6)
                Circle().fill(progress == 1 ? .green : .secondary)
                    .frame(width: 6, height: 6)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .frame(height: 14)
    }
}

#Preview(as: .systemMedium) {
    MediumFlightWidget()
} timeline: {
    FlightEntry(date: Date(), flight: WidgetFlight(
        flightNumber: "UA123",
        departureCode: "SFO",
        arrivalCode: "JFK",
        departureTime: Date().addingTimeInterval(-7200),
        arrivalTime: Date().addingTimeInterval(10800),
        status: "active",
        gate: "G92",
        terminal: "3",
        delayMinutes: 15,
        progress: 0.4
    ), configuration: nil)
}
