import Foundation

protocol UserFlightRepositoryProtocol {
    func getSavedFlights() -> [SavedFlight]
    func saveFlight(_ flight: SavedFlight)
    func deleteFlight(id: String)
    func updateFlight(_ flight: SavedFlight)
    func getFlight(id: String) -> SavedFlight?
}

struct SavedFlight: Identifiable, Codable, Hashable {
    let id: String
    let flightNumber: String
    let date: Date
    var notificationsEnabled: Bool
    let addedAt: Date

    init(flightNumber: String, date: Date, notificationsEnabled: Bool = true) {
        self.id = "\(flightNumber)_\(date.formatted(date: .numeric, time: .omitted))"
        self.flightNumber = flightNumber
        self.date = date
        self.notificationsEnabled = notificationsEnabled
        self.addedAt = Date()
    }
}
