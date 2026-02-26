import XCTest
@testable import SkyTrack

final class FlightDetailViewModelTests: XCTestCase {

    func testInitialState() {
        let vm = FlightDetailViewModel(
            flightId: "UA123",
            trackFlightUseCase: TrackFlightUseCase(flightRepository: MockFlightRepository())
        )

        XCTAssertNil(vm.flight)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.error)
    }

    func testLoadFlight_success() async {
        let mockRepo = MockFlightRepository()
        mockRepo.flightToReturn = TestData.sampleFlight
        let vm = FlightDetailViewModel(
            flightId: "UA123",
            trackFlightUseCase: TrackFlightUseCase(flightRepository: mockRepo)
        )

        await vm.loadFlight()

        XCTAssertNotNil(vm.flight)
        XCTAssertEqual(vm.flight?.flightIata, "UA123")
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.error)
    }

    func testLoadFlight_notFound() async {
        let mockRepo = MockFlightRepository()
        mockRepo.flightToReturn = nil
        let vm = FlightDetailViewModel(
            flightId: "XX999",
            trackFlightUseCase: TrackFlightUseCase(flightRepository: mockRepo)
        )

        await vm.loadFlight()

        XCTAssertNil(vm.flight)
        XCTAssertNotNil(vm.error)
        XCTAssertFalse(vm.isLoading)
    }

    func testLoadFlight_networkError() async {
        let mockRepo = MockFlightRepository()
        mockRepo.errorToThrow = AppError.network(.noConnection)
        let vm = FlightDetailViewModel(
            flightId: "UA123",
            trackFlightUseCase: TrackFlightUseCase(flightRepository: mockRepo)
        )

        await vm.loadFlight()

        XCTAssertNil(vm.flight)
        XCTAssertNotNil(vm.error)
        XCTAssertFalse(vm.isLoading)
    }
}

// MARK: - Mock Flight Repository

final class MockFlightRepository: FlightRepositoryProtocol, @unchecked Sendable {
    var flightToReturn: Flight?
    var flightsToReturn: [Flight] = []
    var positionsToReturn: [FlightPosition] = []
    var errorToThrow: AppError?

    func getFlight(flightNumber: String) async throws -> Flight? {
        if let error = errorToThrow { throw error }
        return flightToReturn
    }

    func searchFlights(query: String) async throws -> [Flight] {
        if let error = errorToThrow { throw error }
        return flightsToReturn
    }

    func getDepartures(airportCode: String) async throws -> [Flight] {
        if let error = errorToThrow { throw error }
        return flightsToReturn
    }

    func getArrivals(airportCode: String) async throws -> [Flight] {
        if let error = errorToThrow { throw error }
        return flightsToReturn
    }

    func getPositions(bounds: MapBounds) async throws -> [FlightPosition] {
        if let error = errorToThrow { throw error }
        return positionsToReturn
    }

    func getActiveFlights() async throws -> [Flight] {
        if let error = errorToThrow { throw error }
        return flightsToReturn
    }
}

// MARK: - Test Data

enum TestData {
    static let sampleFlight = Flight(
        id: "UA123_2026-02-26",
        flightNumber: "123",
        flightIata: "UA123",
        flightIcao: "UAL123",
        airline: Airline(id: "UA", name: "United Airlines", iataCode: "UA", icaoCode: "UAL", country: "US"),
        aircraft: Aircraft(id: "N12345", registration: "N12345", icao24: "A12345", type: "B738", modelName: "Boeing 737-800", manufacturer: "Boeing", age: 5, airlineName: "United Airlines"),
        departure: FlightEndpoint(
            airportIata: "SFO", airportIcao: "KSFO",
            airportName: "San Francisco International",
            city: "San Francisco", country: "United States",
            timezone: "America/Los_Angeles",
            gate: "G92", terminal: "3", baggageClaim: nil,
            scheduledTime: Date(), estimatedTime: Date().addingTimeInterval(900),
            actualTime: Date().addingTimeInterval(900), delayMinutes: 15
        ),
        arrival: FlightEndpoint(
            airportIata: "JFK", airportIcao: "KJFK",
            airportName: "John F Kennedy International",
            city: "New York", country: "United States",
            timezone: "America/New_York",
            gate: "B22", terminal: "7", baggageClaim: "4",
            scheduledTime: Date().addingTimeInterval(18000),
            estimatedTime: Date().addingTimeInterval(18600),
            actualTime: nil, delayMinutes: 10
        ),
        status: .active,
        liveData: LiveFlightData(
            latitude: 39.5, longitude: -98.35,
            altitude: 10972.8, speed: 870, heading: 85,
            verticalSpeed: 0, isGround: false, updated: Date()
        ),
        lastUpdated: Date()
    )

    static let samplePosition = FlightPosition(
        id: "a12345", callsign: "UAL123",
        latitude: 37.621, longitude: -122.379,
        altitude: 10972.8, velocity: 250, trueTrack: 85,
        verticalRate: 0, onGround: false,
        lastUpdate: Date(), originCountry: "United States"
    )
}
