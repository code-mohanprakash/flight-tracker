import XCTest
@testable import SkyTrack

final class SharingServiceTests: XCTestCase {

    private var service: SharingService!

    override func setUp() {
        super.setUp()
        service = SharingService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // MARK: - Tracking URL Tests

    func testLiveTrackingURL_withIata() {
        let flight = TestData.sampleFlight
        let url = service.liveTrackingURL(for: flight)
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "skytrack")
        XCTAssertTrue(url?.absoluteString.contains("UA123") ?? false)
    }

    func testLiveTrackingURL_noIata_returnsNil() {
        let flight = Flight(
            id: "test", flightNumber: "123",
            flightIata: nil, flightIcao: nil,
            airline: nil, aircraft: nil,
            departure: FlightEndpoint(
                airportIata: "SFO", airportIcao: nil, airportName: nil,
                city: nil, country: nil, timezone: nil,
                gate: nil, terminal: nil, baggageClaim: nil,
                scheduledTime: nil, estimatedTime: nil, actualTime: nil, delayMinutes: nil
            ),
            arrival: FlightEndpoint(
                airportIata: "JFK", airportIcao: nil, airportName: nil,
                city: nil, country: nil, timezone: nil,
                gate: nil, terminal: nil, baggageClaim: nil,
                scheduledTime: nil, estimatedTime: nil, actualTime: nil, delayMinutes: nil
            ),
            status: .scheduled,
            liveData: nil,
            lastUpdated: Date()
        )
        XCTAssertNil(service.liveTrackingURL(for: flight))
    }
}

// MARK: - Friends Tracking Tests

final class FriendsTrackingServiceTests: XCTestCase {

    private var service: FriendsTrackingService!

    override func setUp() {
        super.setUp()
        // Clear stored data
        UserDefaults.standard.removeObject(forKey: "skytrack_friends")
        UserDefaults.standard.removeObject(forKey: "skytrack_shared_flights")
        service = FriendsTrackingService()
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "skytrack_friends")
        UserDefaults.standard.removeObject(forKey: "skytrack_shared_flights")
        service = nil
        super.tearDown()
    }

    func testAddFriend() {
        XCTAssertTrue(service.friends.isEmpty)

        let friend = Friend(name: "John")
        service.addFriend(friend)

        XCTAssertEqual(service.friends.count, 1)
        XCTAssertEqual(service.friends[0].name, "John")
        XCTAssertTrue(service.friends[0].isActive)
    }

    func testRemoveFriend() {
        let friend = Friend(name: "Jane")
        service.addFriend(friend)
        XCTAssertEqual(service.friends.count, 1)

        service.removeFriend(id: friend.id)
        XCTAssertTrue(service.friends.isEmpty)
    }

    func testGenerateInviteLink() {
        let url = service.generateInviteLink()
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "skytrack")
        XCTAssertTrue(url?.absoluteString.contains("invite") ?? false)
    }

    func testShareFlight() {
        let friend = Friend(name: "Bob")
        service.addFriend(friend)

        service.shareFlight("UA123", date: Date(), withFriendIds: [friend.id])

        XCTAssertEqual(service.mySharedFlights().count, 1)
        XCTAssertEqual(service.mySharedFlights()[0].flightNumber, "UA123")
    }

    func testStopSharingFlight() {
        let friend = Friend(name: "Alice")
        service.addFriend(friend)
        service.shareFlight("DL456", date: Date(), withFriendIds: [friend.id])
        XCTAssertEqual(service.mySharedFlights().count, 1)

        service.stopSharingFlight("DL456", withFriendId: friend.id)
        XCTAssertTrue(service.mySharedFlights().isEmpty)
    }

    func testRemoveFriend_alsoRemovesSharedFlights() {
        let friend = Friend(name: "Charlie")
        service.addFriend(friend)
        service.shareFlight("BA789", date: Date(), withFriendIds: [friend.id])
        XCTAssertEqual(service.sharedFlights.count, 1)

        service.removeFriend(id: friend.id)
        XCTAssertTrue(service.sharedFlights.isEmpty)
    }

    func testPickupCountdown_activeFlight() {
        let flight = TestData.sampleFlight // status: .active
        let info = service.pickupCountdown(for: flight)
        XCTAssertNotNil(info)
        XCTAssertFalse(info!.isArrived)
        XCTAssertGreaterThan(info!.remainingSeconds, 0)
    }

    func testPickupCountdown_scheduledFlight_returnsNil() {
        let scheduled = Flight(
            id: "test_sched", flightNumber: "123",
            flightIata: "UA123", flightIcao: nil,
            airline: nil, aircraft: nil,
            departure: FlightEndpoint(
                airportIata: "SFO", airportIcao: nil, airportName: nil,
                city: nil, country: nil, timezone: nil,
                gate: nil, terminal: nil, baggageClaim: nil,
                scheduledTime: Date().addingTimeInterval(7200), estimatedTime: nil, actualTime: nil, delayMinutes: nil
            ),
            arrival: FlightEndpoint(
                airportIata: "JFK", airportIcao: nil, airportName: nil,
                city: nil, country: nil, timezone: nil,
                gate: nil, terminal: nil, baggageClaim: nil,
                scheduledTime: Date().addingTimeInterval(25200), estimatedTime: nil, actualTime: nil, delayMinutes: nil
            ),
            status: .scheduled,
            liveData: nil,
            lastUpdated: Date()
        )
        XCTAssertNil(service.pickupCountdown(for: scheduled))
    }
}

// MARK: - Map Filter Tests

final class MapFilterTests: XCTestCase {

    func testDefaultFilter_isNotActive() {
        let filter = MapFilter()
        XCTAssertFalse(filter.isActive)
    }

    func testModifiedFilter_isActive() {
        var filter = MapFilter()
        filter.minAltitude = 10000
        XCTAssertTrue(filter.isActive)
    }

    func testFilter_matchesPosition() {
        let filter = MapFilter()
        let position = TestData.samplePosition
        XCTAssertTrue(filter.matches(position))
    }

    func testFilter_altitudeRange() {
        var filter = MapFilter()
        filter.minAltitude = 40000
        filter.maxAltitude = 45000
        let position = TestData.samplePosition // ~36000 ft
        XCTAssertFalse(filter.matches(position))
    }

    func testFilter_airlineFilter() {
        var filter = MapFilter()
        filter.airlineFilter = "DAL"
        let position = TestData.samplePosition // callsign: UAL123
        XCTAssertFalse(filter.matches(position))
    }

    func testFilter_airlineFilter_matching() {
        var filter = MapFilter()
        filter.airlineFilter = "UAL"
        let position = TestData.samplePosition
        XCTAssertTrue(filter.matches(position))
    }

    func testFilter_hidesOnGround() {
        let filter = MapFilter() // showOnGround = false by default
        let onGround = FlightPosition(
            id: "ground", callsign: "UAL1",
            latitude: 37.62, longitude: -122.38,
            altitude: 0, velocity: 0, trueTrack: 0,
            verticalRate: 0, onGround: true,
            lastUpdate: Date(), originCountry: "US"
        )
        XCTAssertFalse(filter.matches(onGround))
    }
}

// MARK: - AR ViewModel Tests

final class ARSkyViewModelTests: XCTestCase {

    func testInitialState() {
        let mockRepo = MockFlightRepository()
        let vm = ARSkyViewModel(flightRepository: mockRepo)

        XCTAssertTrue(vm.nearbyFlights.isEmpty)
        XCTAssertFalse(vm.isScanning)
        XCTAssertNil(vm.deviceLocation)
    }

    func testOverheadFlight_formattedDistance() {
        let flight = OverheadFlight(
            position: TestData.samplePosition,
            distanceKm: 5.3,
            bearing: 45,
            elevationAngle: 30
        )
        XCTAssertEqual(flight.formattedDistance, "5.3 km")
    }

    func testOverheadFlight_formattedDistance_meters() {
        let flight = OverheadFlight(
            position: TestData.samplePosition,
            distanceKm: 0.5,
            bearing: 90,
            elevationAngle: 60
        )
        XCTAssertEqual(flight.formattedDistance, "500 m")
    }

    func testOverheadFlight_compassDirection() {
        let north = OverheadFlight(position: TestData.samplePosition, distanceKm: 1, bearing: 5, elevationAngle: 45)
        XCTAssertEqual(north.compassDirection, "N")

        let east = OverheadFlight(position: TestData.samplePosition, distanceKm: 1, bearing: 90, elevationAngle: 45)
        XCTAssertEqual(east.compassDirection, "E")

        let south = OverheadFlight(position: TestData.samplePosition, distanceKm: 1, bearing: 180, elevationAngle: 45)
        XCTAssertEqual(south.compassDirection, "S")

        let west = OverheadFlight(position: TestData.samplePosition, distanceKm: 1, bearing: 270, elevationAngle: 45)
        XCTAssertEqual(west.compassDirection, "W")
    }
}

// MARK: - TravelStats Tests

final class TravelStatsServiceTests: XCTestCase {

    func testInitialState() {
        let mockUserRepo = MockUserFlightRepository()
        let mockFlightRepo = MockFlightRepository()
        let service = TravelStatsService(
            userFlightRepository: mockUserRepo,
            flightRepository: mockFlightRepo
        )

        XCTAssertNil(service.stats)
        XCTAssertFalse(service.isLoading)
    }

    func testComputeStats_noFlights() async {
        let mockUserRepo = MockUserFlightRepository()
        let mockFlightRepo = MockFlightRepository()
        let service = TravelStatsService(
            userFlightRepository: mockUserRepo,
            flightRepository: mockFlightRepo
        )

        await service.computeStats()

        XCTAssertNotNil(service.stats)
        XCTAssertEqual(service.stats?.totalFlights, 0)
        XCTAssertFalse(service.isLoading)
    }

    func testComputeStats_withFlights() async {
        let mockUserRepo = MockUserFlightRepository()
        mockUserRepo.flights = [
            SavedFlight(flightNumber: "UA123", date: Date()),
            SavedFlight(flightNumber: "DL456", date: Date()),
        ]

        let mockFlightRepo = MockFlightRepository()
        mockFlightRepo.flightToReturn = TestData.sampleFlight

        let service = TravelStatsService(
            userFlightRepository: mockUserRepo,
            flightRepository: mockFlightRepo
        )

        await service.computeStats()

        XCTAssertNotNil(service.stats)
        XCTAssertEqual(service.stats?.totalFlights, 2)
    }

    func testTravelStats_earthCircumferences() {
        let stats = TravelStats(
            totalFlights: 10,
            totalDistanceKm: 80150,
            totalDurationMinutes: 600,
            uniqueAirports: 5,
            uniqueCities: 5,
            uniqueCountries: 3,
            topAirlines: [],
            topAircraft: [],
            topRoutes: [],
            onTimeRate: 0.9,
            totalDelayMinutes: 30,
            delayedFlightCount: 1,
            monthlyDistribution: [:],
            visitedAirports: [],
            flightHistory: []
        )
        XCTAssertEqual(stats.earthCircumferences, 2.0, accuracy: 0.01)
    }
}

// MARK: - Mock User Flight Repository

final class MockUserFlightRepository: UserFlightRepositoryProtocol {
    var flights: [SavedFlight] = []

    func getSavedFlights() -> [SavedFlight] { flights }
    func saveFlight(_ flight: SavedFlight) { flights.append(flight) }
    func deleteFlight(id: String) { flights.removeAll { $0.id == id } }
    func updateFlight(_ flight: SavedFlight) {
        if let idx = flights.firstIndex(where: { $0.id == flight.id }) {
            flights[idx] = flight
        }
    }
    func getFlight(id: String) -> SavedFlight? { flights.first { $0.id == id } }
}
