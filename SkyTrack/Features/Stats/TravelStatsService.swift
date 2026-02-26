import Foundation

/// Computes travel statistics from flight history.
@Observable
final class TravelStatsService {
    var stats: TravelStats?
    var isLoading = false

    private let userFlightRepository: UserFlightRepositoryProtocol
    private let flightRepository: FlightRepositoryProtocol

    init(userFlightRepository: UserFlightRepositoryProtocol, flightRepository: FlightRepositoryProtocol) {
        self.userFlightRepository = userFlightRepository
        self.flightRepository = flightRepository
    }

    // MARK: - Compute Stats

    func computeStats() async {
        isLoading = true
        defer { isLoading = false }

        let savedFlights = userFlightRepository.getSavedFlights()
        var flightHistory: [FlightRecord] = []

        for saved in savedFlights {
            do {
                if let flight = try await flightRepository.getFlight(flightNumber: saved.flightNumber) {
                    flightHistory.append(FlightRecord(
                        flightNumber: saved.flightNumber,
                        date: saved.date,
                        origin: flight.departure.airportIata ?? "???",
                        destination: flight.arrival.airportIata ?? "???",
                        originCity: flight.departure.city,
                        destinationCity: flight.arrival.city,
                        originCountry: flight.departure.country,
                        destinationCountry: flight.arrival.country,
                        airline: flight.airline?.name,
                        airlineCode: flight.airline?.iataCode,
                        aircraftType: flight.aircraft?.modelName,
                        distance: estimateDistance(flight),
                        durationMinutes: estimateDuration(flight),
                        wasDelayed: flight.delayMinutes ?? 0 > 15,
                        delayMinutes: flight.delayMinutes ?? 0,
                        status: flight.status
                    ))
                }
            } catch {
                // Record with basic info only
                flightHistory.append(FlightRecord(
                    flightNumber: saved.flightNumber,
                    date: saved.date,
                    origin: "???", destination: "???",
                    originCity: nil, destinationCity: nil,
                    originCountry: nil, destinationCountry: nil,
                    airline: nil, airlineCode: nil, aircraftType: nil,
                    distance: nil, durationMinutes: nil,
                    wasDelayed: false, delayMinutes: 0, status: .unknown
                ))
            }
        }

        stats = computeFromRecords(flightHistory)
    }

    // MARK: - Computation

    private func computeFromRecords(_ records: [FlightRecord]) -> TravelStats {
        let totalFlights = records.count
        let totalDistance = records.compactMap(\.distance).reduce(0, +)
        let totalDuration = records.compactMap(\.durationMinutes).reduce(0, +)

        // Unique places
        let allAirports = Set(records.map(\.origin) + records.map(\.destination))
        let allCities = Set(records.compactMap(\.originCity) + records.compactMap(\.destinationCity))
        let allCountries = Set(records.compactMap(\.originCountry) + records.compactMap(\.destinationCountry))

        // Airlines
        var airlineFlights: [String: Int] = [:]
        for record in records {
            if let airline = record.airline {
                airlineFlights[airline, default: 0] += 1
            }
        }
        let topAirlines = airlineFlights.sorted { $0.value > $1.value }
            .prefix(5)
            .map { AirlineStat(name: $0.key, flightCount: $0.value) }

        // Aircraft types
        var aircraftFlights: [String: Int] = [:]
        for record in records {
            if let type = record.aircraftType {
                aircraftFlights[type, default: 0] += 1
            }
        }
        let topAircraft = aircraftFlights.sorted { $0.value > $1.value }
            .prefix(5)
            .map { AircraftStat(name: $0.key, flightCount: $0.value) }

        // Busiest routes
        var routes: [String: Int] = [:]
        for record in records {
            let route = "\(record.origin)-\(record.destination)"
            routes[route, default: 0] += 1
        }
        let topRoutes = routes.sorted { $0.value > $1.value }
            .prefix(5)
            .map { RouteStat(route: $0.key, flightCount: $0.value) }

        // Delays
        let delayedFlights = records.filter(\.wasDelayed)
        let totalDelayMinutes = delayedFlights.map(\.delayMinutes).reduce(0, +)
        let onTimeRate = totalFlights > 0 ? Double(totalFlights - delayedFlights.count) / Double(totalFlights) : 1.0

        // Monthly distribution
        var monthlyFlights: [Int: Int] = [:]
        let calendar = Calendar.current
        for record in records {
            let month = calendar.component(.month, from: record.date)
            monthlyFlights[month, default: 0] += 1
        }

        // Airports visited with coordinates for world map
        let visitedAirports = Array(allAirports).map { code in
            VisitedAirport(code: code, visitCount: records.filter { $0.origin == code || $0.destination == code }.count)
        }.sorted { $0.visitCount > $1.visitCount }

        return TravelStats(
            totalFlights: totalFlights,
            totalDistanceKm: totalDistance,
            totalDurationMinutes: totalDuration,
            uniqueAirports: allAirports.count,
            uniqueCities: allCities.count,
            uniqueCountries: allCountries.count,
            topAirlines: Array(topAirlines),
            topAircraft: Array(topAircraft),
            topRoutes: Array(topRoutes),
            onTimeRate: onTimeRate,
            totalDelayMinutes: totalDelayMinutes,
            delayedFlightCount: delayedFlights.count,
            monthlyDistribution: monthlyFlights,
            visitedAirports: visitedAirports,
            flightHistory: records
        )
    }

    // MARK: - Estimations

    private func estimateDistance(_ flight: Flight) -> Double? {
        // Simple great circle distance from airport positions
        // In production, use actual airport coordinates
        nil
    }

    private func estimateDuration(_ flight: Flight) -> Int? {
        guard let dep = flight.departure.scheduledTime,
              let arr = flight.arrival.scheduledTime else { return nil }
        return Int(arr.timeIntervalSince(dep) / 60)
    }
}

// MARK: - Models

struct TravelStats {
    let totalFlights: Int
    let totalDistanceKm: Double
    let totalDurationMinutes: Int
    let uniqueAirports: Int
    let uniqueCities: Int
    let uniqueCountries: Int
    let topAirlines: [AirlineStat]
    let topAircraft: [AircraftStat]
    let topRoutes: [RouteStat]
    let onTimeRate: Double
    let totalDelayMinutes: Int
    let delayedFlightCount: Int
    let monthlyDistribution: [Int: Int]
    let visitedAirports: [VisitedAirport]
    let flightHistory: [FlightRecord]

    var totalHours: Int { totalDurationMinutes / 60 }

    var formattedDistance: String {
        if totalDistanceKm > 1_000_000 {
            return String(format: "%.1fM km", totalDistanceKm / 1_000_000)
        } else if totalDistanceKm > 1000 {
            return String(format: "%.0fK km", totalDistanceKm / 1000)
        }
        return "\(Int(totalDistanceKm)) km"
    }

    var earthCircumferences: Double {
        totalDistanceKm / 40_075 // Earth's circumference
    }
}

struct FlightRecord: Identifiable {
    var id: String { "\(flightNumber)_\(date.timeIntervalSince1970)" }
    let flightNumber: String
    let date: Date
    let origin: String
    let destination: String
    let originCity: String?
    let destinationCity: String?
    let originCountry: String?
    let destinationCountry: String?
    let airline: String?
    let airlineCode: String?
    let aircraftType: String?
    let distance: Double?
    let durationMinutes: Int?
    let wasDelayed: Bool
    let delayMinutes: Int
    let status: FlightStatus
}

struct AirlineStat: Identifiable {
    var id: String { name }
    let name: String
    let flightCount: Int
}

struct AircraftStat: Identifiable {
    var id: String { name }
    let name: String
    let flightCount: Int
}

struct RouteStat: Identifiable {
    var id: String { route }
    let route: String
    let flightCount: Int
}

struct VisitedAirport: Identifiable {
    var id: String { code }
    let code: String
    let visitCount: Int
}
