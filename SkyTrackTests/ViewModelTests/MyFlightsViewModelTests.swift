import XCTest
@testable import SkyTrack

final class MyFlightsViewModelTests: XCTestCase {

    private var mockUserRepo: MockUserFlightRepository!
    private var mockFlightRepo: MockFlightRepository!

    override func setUp() {
        super.setUp()
        mockUserRepo = MockUserFlightRepository()
        mockFlightRepo = MockFlightRepository()
    }

    func testInitialState() {
        let vm = createViewModel()
        XCTAssertTrue(vm.savedFlights.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.error)
        XCTAssertFalse(vm.showingAddFlight)
    }

    func testLoadFlights() {
        mockUserRepo.flights = [
            SavedFlight(flightNumber: "UA123", date: Date()),
            SavedFlight(flightNumber: "DL456", date: Date()),
        ]

        let vm = createViewModel()
        vm.loadFlights()

        XCTAssertEqual(vm.savedFlights.count, 2)
    }

    func testAddFlight_success() {
        let vm = createViewModel()
        vm.newFlightNumber = "UA123"
        vm.newFlightDate = Date()

        vm.addFlight()

        XCTAssertEqual(mockUserRepo.flights.count, 1)
        XCTAssertEqual(mockUserRepo.flights.first?.flightNumber, "UA123")
        XCTAssertEqual(vm.newFlightNumber, "")
        XCTAssertNil(vm.addFlightError)
        XCTAssertFalse(vm.showingAddFlight)
    }

    func testAddFlight_emptyNumber() {
        let vm = createViewModel()
        vm.newFlightNumber = ""

        vm.addFlight()

        XCTAssertEqual(mockUserRepo.flights.count, 0)
        XCTAssertNotNil(vm.addFlightError)
    }

    func testAddFlight_tooShort() {
        let vm = createViewModel()
        vm.newFlightNumber = "UA"

        vm.addFlight()

        XCTAssertEqual(mockUserRepo.flights.count, 0)
        XCTAssertNotNil(vm.addFlightError)
    }

    func testDeleteFlight() {
        let saved = SavedFlight(flightNumber: "UA123", date: Date())
        mockUserRepo.flights = [saved]

        let vm = createViewModel()
        vm.loadFlights()
        vm.deleteFlight(saved)

        XCTAssertTrue(mockUserRepo.flights.isEmpty)
    }

    func testUpcomingAndPast_segregation() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        mockUserRepo.flights = [
            SavedFlight(flightNumber: "UA123", date: tomorrow),
            SavedFlight(flightNumber: "DL456", date: yesterday),
        ]

        let vm = createViewModel()
        vm.loadFlights()

        XCTAssertEqual(vm.upcomingFlights.count, 1)
        XCTAssertEqual(vm.pastFlights.count, 1)
        XCTAssertEqual(vm.upcomingFlights.first?.flightNumber, "UA123")
        XCTAssertEqual(vm.pastFlights.first?.flightNumber, "DL456")
    }

    func testIsEmpty() {
        let vm = createViewModel()
        vm.loadFlights()
        XCTAssertTrue(vm.isEmpty)

        mockUserRepo.flights = [SavedFlight(flightNumber: "UA123", date: Date())]
        vm.loadFlights()
        XCTAssertFalse(vm.isEmpty)
    }

    // MARK: - Helpers

    private func createViewModel() -> MyFlightsViewModel {
        MyFlightsViewModel(
            userFlightRepository: mockUserRepo,
            flightRepository: mockFlightRepo
        )
    }
}

// MARK: - Mock User Flight Repository

final class MockUserFlightRepository: UserFlightRepositoryProtocol {
    var flights: [SavedFlight] = []

    func getSavedFlights() -> [SavedFlight] {
        flights.sorted { $0.date > $1.date }
    }

    func saveFlight(_ flight: SavedFlight) {
        flights.append(flight)
    }

    func deleteFlight(id: String) {
        flights.removeAll { $0.id == id }
    }

    func updateFlight(_ flight: SavedFlight) {
        if let index = flights.firstIndex(where: { $0.id == flight.id }) {
            flights[index] = flight
        }
    }

    func getFlight(id: String) -> SavedFlight? {
        flights.first { $0.id == id }
    }
}
