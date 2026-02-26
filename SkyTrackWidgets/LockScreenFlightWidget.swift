import WidgetKit
import SwiftUI

struct LockScreenFlightWidget: Widget {
    let kind = "LockScreenFlightWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FlightTimelineProvider()) { entry in
            LockScreenFlightWidgetView(entry: entry)
        }
        .configurationDisplayName("Flight Countdown")
        .description("Quick flight status on your lock screen.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Lock Screen Views

struct LockScreenFlightWidgetView: View {
    let entry: FlightEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .accessoryInline:
            inlineView
        default:
            circularView
        }
    }

    // MARK: - Circular (small round widget)

    private var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            if let flight = entry.flight {
                VStack(spacing: 1) {
                    Image(systemName: "airplane")
                        .font(.system(size: 12, weight: .bold))
                    Text(flight.countdownText)
                        .font(.system(size: 14, weight: .bold))
                        .minimumScaleFactor(0.6)
                    Text(flight.flightNumber)
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
            } else {
                Image(systemName: "airplane.circle")
                    .font(.system(size: 24))
            }
        }
    }

    // MARK: - Rectangular (larger lock screen widget)

    private var rectangularView: some View {
        Group {
            if let flight = entry.flight {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(flight.flightNumber)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                        Spacer()
                        if flight.isDelayed {
                            Text("DELAYED")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack {
                        Text(flight.departureCode)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 8))
                        Text(flight.arrivalCode)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        Spacer()
                        if let gate = flight.gate {
                            Text("Gate \(gate)")
                                .font(.system(size: 10))
                        }
                    }

                    HStack {
                        if let depTime = flight.departureTime {
                            Text(depTime.formatted(date: .omitted, time: .shortened))
                                .font(.system(size: 11, design: .monospaced))
                        }
                        Spacer()
                        Text(flight.countdownText)
                            .font(.system(size: 11, weight: .bold))
                    }
                }
            } else {
                HStack {
                    Image(systemName: "airplane.circle")
                    Text("No flights")
                        .font(.system(size: 13))
                }
            }
        }
    }

    // MARK: - Inline (single line on lock screen)

    private var inlineView: some View {
        Group {
            if let flight = entry.flight {
                Label {
                    Text("\(flight.flightNumber) \(flight.departureCode)→\(flight.arrivalCode) \(flight.countdownText)")
                } icon: {
                    Image(systemName: "airplane")
                }
            } else {
                Label("No flights", systemImage: "airplane.circle")
            }
        }
    }
}

#Preview(as: .accessoryRectangular) {
    LockScreenFlightWidget()
} timeline: {
    FlightEntry(date: Date(), flight: .placeholder, configuration: nil)
}
