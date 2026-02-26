import Foundation
import os

final class UserFlightRepository: UserFlightRepositoryProtocol {
    private let defaults: UserDefaults
    private let key = "com.skytrack.savedFlights"
    private static let logger = Logger(subsystem: "com.skytrack.app", category: "user-flights")

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func getSavedFlights() -> [SavedFlight] {
        guard let data = defaults.data(forKey: key) else { return [] }
        do {
            return try JSONDecoder().decode([SavedFlight].self, from: data)
                .sorted { $0.date > $1.date }
        } catch {
            Self.logger.error("Failed to decode saved flights: \(error)")
            return []
        }
    }

    func saveFlight(_ flight: SavedFlight) {
        var flights = getSavedFlights()
        if flights.contains(where: { $0.id == flight.id }) {
            Self.logger.warning("Flight \(flight.flightNumber) already saved")
            return
        }
        flights.append(flight)
        persist(flights)
        Self.logger.info("Saved flight \(flight.flightNumber)")
    }

    func deleteFlight(id: String) {
        var flights = getSavedFlights()
        flights.removeAll { $0.id == id }
        persist(flights)
        Self.logger.info("Deleted flight \(id)")
    }

    func updateFlight(_ flight: SavedFlight) {
        var flights = getSavedFlights()
        if let index = flights.firstIndex(where: { $0.id == flight.id }) {
            flights[index] = flight
            persist(flights)
        }
    }

    func getFlight(id: String) -> SavedFlight? {
        getSavedFlights().first { $0.id == id }
    }

    private func persist(_ flights: [SavedFlight]) {
        do {
            let data = try JSONEncoder().encode(flights)
            defaults.set(data, forKey: key)
        } catch {
            Self.logger.error("Failed to persist flights: \(error)")
        }
    }
}
