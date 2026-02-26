import XCTest
@testable import SkyTrack

final class FlightTrackingServiceTests: XCTestCase {

    private var service: FlightTrackingService!
    private var mockFlightRepo: MockFlightRepository!
    private var mockAirportRepo: MockAirportRepository!
    private var predictionService: DelayPredictionService!
    private var notificationService: NotificationService!

    override func setUp() {
        super.setUp()
        mockFlightRepo = MockFlightRepository()
        mockAirportRepo = MockAirportRepository()
        predictionService = DelayPredictionService(
            flightRepository: mockFlightRepo,
            airportRepository: mockAirportRepo
        )
        notificationService = NotificationService()
        service = FlightTrackingService(
            flightRepository: mockFlightRepo,
            delayPredictionService: predictionService,
            notificationService: notificationService
        )
    }

    override func tearDown() {
        service.stopTracking()
        service = nil
        mockFlightRepo = nil
        mockAirportRepo = nil
        predictionService = nil
        notificationService = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertTrue(service.trackedFlights.isEmpty)
        XCTAssertTrue(service.predictions.isEmpty)
        XCTAssertFalse(service.isTracking)
    }

    // MARK: - Add/Remove Flights

    func testAddFlight_success() async {
        mockFlightRepo.flightToReturn = TestData.sampleFlight
        mockFlightRepo.flightsToReturn = [] // For congestion check

        await service.addFlight("UA123")

        XCTAssertEqual(service.trackedFlights.count, 1)
        XCTAssertNotNil(service.trackedFlights["UA123"])
    }

    func testAddFlight_notFound() async {
        mockFlightRepo.flightToReturn = nil

        await service.addFlight("XX999")

        XCTAssertTrue(service.trackedFlights.isEmpty)
    }

    func testAddFlight_error() async {
        mockFlightRepo.errorToThrow = AppError.network(.noConnection)

        await service.addFlight("UA123")

        XCTAssertTrue(service.trackedFlights.isEmpty)
    }

    func testRemoveFlight() async {
        mockFlightRepo.flightToReturn = TestData.sampleFlight
        mockFlightRepo.flightsToReturn = []
        await service.addFlight("UA123")
        XCTAssertEqual(service.trackedFlights.count, 1)

        service.removeFlight("UA123")

        XCTAssertTrue(service.trackedFlights.isEmpty)
        XCTAssertTrue(service.predictions.isEmpty)
    }

    // MARK: - Tracking Lifecycle

    func testStartTracking_setsIsTracking() {
        service.startTracking(flightNumbers: ["UA123"])

        XCTAssertTrue(service.isTracking)
    }

    func testStopTracking_clearsIsTracking() {
        service.startTracking(flightNumbers: ["UA123"])
        XCTAssertTrue(service.isTracking)

        service.stopTracking()

        XCTAssertFalse(service.isTracking)
    }

    func testStartTracking_replacesExistingTask() {
        service.startTracking(flightNumbers: ["UA123"])
        XCTAssertTrue(service.isTracking)

        service.startTracking(flightNumbers: ["DL456"])
        XCTAssertTrue(service.isTracking)
    }

    // MARK: - Prediction Generation

    func testAddFlight_generatesPrediction_forActiveFlight() async {
        mockFlightRepo.flightToReturn = TestData.sampleFlight // status: .active
        mockFlightRepo.flightsToReturn = []

        await service.addFlight("UA123")

        XCTAssertNotNil(service.predictions["UA123"])
    }

    func testAddFlight_noPrediction_forLandedFlight() async {
        let landedFlight = Flight(
            id: "test_landed",
            flightNumber: "123",
            flightIata: "UA123",
            flightIcao: nil,
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
            status: .landed,
            liveData: nil,
            lastUpdated: Date()
        )
        mockFlightRepo.flightToReturn = landedFlight
        mockFlightRepo.flightsToReturn = []

        await service.addFlight("UA123")

        XCTAssertNil(service.predictions["UA123"])
    }
}
