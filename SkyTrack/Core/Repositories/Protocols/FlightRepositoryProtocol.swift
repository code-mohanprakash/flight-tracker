import Foundation

protocol FlightRepositoryProtocol: Sendable {
    func getFlight(flightNumber: String) async throws -> Flight?
    func searchFlights(query: String) async throws -> [Flight]
    func getDepartures(airportCode: String) async throws -> [Flight]
    func getArrivals(airportCode: String) async throws -> [Flight]
    func getPositions(bounds: MapBounds) async throws -> [FlightPosition]
    func getActiveFlights() async throws -> [Flight]
}
