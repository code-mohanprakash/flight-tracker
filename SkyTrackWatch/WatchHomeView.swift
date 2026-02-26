import SwiftUI

struct WatchHomeView: View {
    @State private var currentFlight: WatchFlightData?
    @State private var upcomingFlights: [WatchFlightData] = []

    var body: some View {
        NavigationStack {
            Group {
                if let flight = currentFlight {
                    activeFlightView(flight)
                } else if !upcomingFlights.isEmpty {
                    upcomingFlightsList
                } else {
                    emptyState
                }
            }
            .navigationTitle("SkyTrack")
            .onAppear { loadFlightData() }
        }
    }

    // MARK: - Active Flight View

    private func activeFlightView(_ flight: WatchFlightData) -> some View {
        ScrollView {
            VStack(spacing: 8) {
                // Flight number + status
                HStack {
                    Text(flight.flightNumber)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                    Spacer()
                    Text(flight.statusDisplay)
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(flight.statusColor.opacity(0.2))
                        .foregroundStyle(flight.statusColor)
                        .clipShape(Capsule())
                }

                // Route
                HStack {
                    Text(flight.departureCode)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(flight.arrivalCode)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                }

                // Progress bar
                ProgressView(value: flight.progress)
                    .tint(.blue)

                Divider()

                // Details grid
                if let gate = flight.gate {
                    detailRow(icon: "door.left.hand.open", label: "Gate", value: gate)
                }
                if let depTime = flight.departureTime {
                    detailRow(icon: "airplane.departure", label: "Departs",
                              value: depTime.formatted(date: .omitted, time: .shortened))
                }
                if let arrTime = flight.arrivalTime {
                    detailRow(icon: "airplane.arrival", label: "Arrives",
                              value: arrTime.formatted(date: .omitted, time: .shortened))
                }
                if let delay = flight.delayMinutes, delay > 0 {
                    detailRow(icon: "clock.fill", label: "Delay", value: "+\(delay) min")
                        .foregroundStyle(.orange)
                }
                if let altitude = flight.altitude {
                    detailRow(icon: "arrow.up.to.line", label: "Altitude", value: "\(altitude) ft")
                }
            }
        }
    }

    // MARK: - Upcoming Flights List

    private var upcomingFlightsList: some View {
        List(upcomingFlights) { flight in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(flight.flightNumber)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                    Spacer()
                    Text(flight.countdownText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.blue)
                }
                HStack {
                    Text("\(flight.departureCode) → \(flight.arrivalCode)")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let gate = flight.gate {
                        Text("G\(gate)")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "airplane.circle")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("No Flights")
                .font(.system(size: 14, weight: .medium))
            Text("Add flights on iPhone")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 12))
                .frame(width: 20)
                .foregroundStyle(.blue)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
        }
    }

    private func loadFlightData() {
        // Load from shared UserDefaults via Watch Connectivity
        guard let data = UserDefaults(suiteName: "group.com.skytrack.app")?
            .data(forKey: "watchFlights"),
              let flights = try? JSONDecoder().decode([WatchFlightData].self, from: data) else {
            return
        }

        let active = flights.first { $0.status == "active" }
        currentFlight = active
        upcomingFlights = flights.filter { $0.status != "active" }
    }
}

// MARK: - Watch Flight Data

struct WatchFlightData: Identifiable, Codable {
    let id: String
    let flightNumber: String
    let departureCode: String
    let arrivalCode: String
    let departureTime: Date?
    let arrivalTime: Date?
    let status: String
    let gate: String?
    let delayMinutes: Int?
    let progress: Double
    let altitude: Int?

    var statusDisplay: String {
        switch status {
        case "active": return "In Air"
        case "landed": return "Landed"
        case "cancelled": return "Cancelled"
        case "scheduled":
            return (delayMinutes ?? 0) > 5 ? "Delayed" : "On Time"
        default: return status.capitalized
        }
    }

    var statusColor: Color {
        switch status {
        case "active": return .blue
        case "landed": return .green
        case "cancelled": return .red
        default: return (delayMinutes ?? 0) > 5 ? .orange : .green
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
}
