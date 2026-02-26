import Foundation
import os

@Observable
final class MyFlightsViewModel {
    // MARK: - State
    var savedFlights: [SavedFlight] = []
    var flightDetails: [String: Flight] = [:]
    var isLoading = false
    var error: AppError?
    var showingAddFlight = false

    // For adding new flights
    var newFlightNumber: String = ""
    var newFlightDate: Date = Date()
    var addFlightError: String?

    // MARK: - Private
    private let userFlightRepository: UserFlightRepositoryProtocol
    private let flightRepository: FlightRepositoryProtocol
    private static let logger = Logger(subsystem: "com.skytrack.app", category: "my-flights")

    init(userFlightRepository: UserFlightRepositoryProtocol, flightRepository: FlightRepositoryProtocol) {
        self.userFlightRepository = userFlightRepository
        self.flightRepository = flightRepository
    }

    // MARK: - Computed

    var upcomingFlights: [SavedFlight] {
        savedFlights.filter { $0.date >= Calendar.current.startOfDay(for: Date()) }
            .sorted { $0.date < $1.date }
    }

    var pastFlights: [SavedFlight] {
        savedFlights.filter { $0.date < Calendar.current.startOfDay(for: Date()) }
            .sorted { $0.date > $1.date }
    }

    var isEmpty: Bool {
        savedFlights.isEmpty
    }

    // MARK: - Actions

    func loadFlights() {
        savedFlights = userFlightRepository.getSavedFlights()
        Self.logger.info("Loaded \(self.savedFlights.count) saved flights")
    }

    func refreshFlightDetails() async {
        isLoading = true
        for saved in savedFlights {
            do {
                if let flight = try await flightRepository.getFlight(flightNumber: saved.flightNumber) {
                    await MainActor.run {
                        flightDetails[saved.id] = flight
                    }
                }
            } catch {
                Self.logger.warning("Failed to load details for \(saved.flightNumber): \(error)")
            }
        }
        await MainActor.run { isLoading = false }
    }

    func addFlight() {
        let number = newFlightNumber.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !number.isEmpty else {
            addFlightError = "Please enter a flight number"
            return
        }
        guard number.count >= 3 else {
            addFlightError = "Invalid flight number"
            return
        }

        let savedFlight = SavedFlight(
            flightNumber: number,
            date: newFlightDate
        )

        // Check for duplicates
        if savedFlights.contains(where: { $0.id == savedFlight.id }) {
            addFlightError = "This flight is already saved"
            return
        }

        userFlightRepository.saveFlight(savedFlight)
        loadFlights()

        // Reset form
        newFlightNumber = ""
        newFlightDate = Date()
        addFlightError = nil
        showingAddFlight = false

        Self.logger.info("Added flight \(number)")
    }

    func deleteFlight(_ saved: SavedFlight) {
        userFlightRepository.deleteFlight(id: saved.id)
        flightDetails.removeValue(forKey: saved.id)
        loadFlights()
        Self.logger.info("Deleted flight \(saved.flightNumber)")
    }

    func toggleNotifications(for saved: SavedFlight) {
        var updated = saved
        updated.notificationsEnabled.toggle()
        userFlightRepository.updateFlight(updated)
        loadFlights()
    }
}
