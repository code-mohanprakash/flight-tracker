import XCTest
@testable import SkyTrack

final class DelayPredictionServiceTests: XCTestCase {

    private var service: DelayPredictionService!
    private var mockFlightRepo: MockFlightRepository!
    private var mockAirportRepo: MockAirportRepository!

    override func setUp() {
        super.setUp()
        mockFlightRepo = MockFlightRepository()
        mockAirportRepo = MockAirportRepository()
        service = DelayPredictionService(
            flightRepository: mockFlightRepo,
            airportRepository: mockAirportRepo
        )
    }

    override func tearDown() {
        service = nil
        mockFlightRepo = nil
        mockAirportRepo = nil
        super.tearDown()
    }

    // MARK: - Prediction Tests

    func testPredict_onTimeFlight_lowDelay() async {
        let flight = makeTestFlight(delayMinutes: 0, departureHour: 7)
        mockFlightRepo.flightsToReturn = [] // No departures for congestion check

        let prediction = await service.predict(for: flight)

        XCTAssertGreaterThanOrEqual(prediction.predictedDelayMinutes, 0)
        XCTAssertGreaterThan(prediction.confidence, 0)
        XCTAssertLessThanOrEqual(prediction.confidence, 1.0)
        XCTAssertFalse(prediction.isExpired)
    }

    func testPredict_delayedFlight_higherPrediction() async {
        let flight = makeTestFlight(delayMinutes: 30, departureHour: 19)
        mockFlightRepo.flightsToReturn = []

        let prediction = await service.predict(for: flight)

        XCTAssertGreaterThan(prediction.predictedDelayMinutes, 0)
        XCTAssertNotNil(prediction.primaryReason)
    }

    func testPredict_setsCurrentPrediction() async {
        let flight = makeTestFlight(delayMinutes: 10, departureHour: 12)
        mockFlightRepo.flightsToReturn = []
        XCTAssertNil(service.currentPrediction)

        _ = await service.predict(for: flight)

        XCTAssertNotNil(service.currentPrediction)
    }

    func testPredict_includesMultipleFactors() async {
        let flight = makeTestFlight(delayMinutes: 15, departureHour: 14)
        mockFlightRepo.flightsToReturn = []

        let prediction = await service.predict(for: flight)

        // Should have at least: historical, timeOfDay, congestion, cascade
        XCTAssertGreaterThanOrEqual(prediction.factors.count, 4)
    }

    func testPredict_factorsSortedByWeight() async {
        let flight = makeTestFlight(delayMinutes: 20, departureHour: 16)
        mockFlightRepo.flightsToReturn = []

        let prediction = await service.predict(for: flight)

        for i in 0..<prediction.factors.count - 1 {
            XCTAssertGreaterThanOrEqual(prediction.factors[i].weight, prediction.factors[i + 1].weight)
        }
    }

    func testPredict_confidenceBounded() async {
        let flight = makeTestFlight(delayMinutes: 0, departureHour: 8)
        mockFlightRepo.flightsToReturn = []

        let prediction = await service.predict(for: flight)

        XCTAssertGreaterThanOrEqual(prediction.confidence, 0.0)
        XCTAssertLessThanOrEqual(prediction.confidence, 0.95)
    }

    func testPredict_validUntil30MinAhead() async {
        let flight = makeTestFlight(delayMinutes: 0, departureHour: 10)
        mockFlightRepo.flightsToReturn = []

        let prediction = await service.predict(for: flight)

        let expectedValidity = prediction.generatedAt.addingTimeInterval(1800)
        XCTAssertEqual(prediction.validUntil.timeIntervalSince1970, expectedValidity.timeIntervalSince1970, accuracy: 2)
    }

    // MARK: - Inbound Aircraft Tests

    func testTrackInboundAircraft_noAircraft_returnsNil() async {
        let flight = makeTestFlight(delayMinutes: 0, departureHour: 10, aircraft: nil)

        let inbound = await service.trackInboundAircraft(for: flight)

        XCTAssertNil(inbound)
    }

    func testTrackInboundAircraft_noRegistration_returnsNil() async {
        let noRegAircraft = Aircraft(
            id: "test", registration: nil, icao24: nil,
            type: "B738", modelName: "Boeing 737-800",
            manufacturer: "Boeing", age: nil, airlineName: nil
        )
        let flight = makeTestFlight(delayMinutes: 0, departureHour: 10, aircraft: noRegAircraft)

        let inbound = await service.trackInboundAircraft(for: flight)

        XCTAssertNil(inbound)
    }

    // MARK: - DelayPrediction Model Tests

    func testDelayPrediction_isExpired() {
        let expired = DelayPrediction(
            flightId: "test",
            predictedDelayMinutes: 10,
            confidence: 0.6,
            primaryReason: .lateAircraft,
            factors: [],
            inboundFlightId: nil,
            generatedAt: Date().addingTimeInterval(-3600),
            validUntil: Date().addingTimeInterval(-1800)
        )
        XCTAssertTrue(expired.isExpired)

        let valid = DelayPrediction(
            flightId: "test",
            predictedDelayMinutes: 10,
            confidence: 0.6,
            primaryReason: .lateAircraft,
            factors: [],
            inboundFlightId: nil,
            generatedAt: Date(),
            validUntil: Date().addingTimeInterval(1800)
        )
        XCTAssertFalse(valid.isExpired)
    }

    func testDelayPrediction_confidenceLabel() {
        let high = makeSimplePrediction(confidence: 0.85)
        XCTAssertEqual(high.confidenceLabel, "High")

        let medium = makeSimplePrediction(confidence: 0.65)
        XCTAssertEqual(medium.confidenceLabel, "Medium")

        let low = makeSimplePrediction(confidence: 0.45)
        XCTAssertEqual(low.confidenceLabel, "Low")

        let veryLow = makeSimplePrediction(confidence: 0.2)
        XCTAssertEqual(veryLow.confidenceLabel, "Very Low")
    }

    func testDelayPrediction_isLikelyDelayed() {
        let likely = makeSimplePrediction(delayMinutes: 20, confidence: 0.6)
        XCTAssertTrue(likely.isLikelyDelayed)

        let lowConfidence = makeSimplePrediction(delayMinutes: 20, confidence: 0.3)
        XCTAssertFalse(lowConfidence.isLikelyDelayed)

        let lowDelay = makeSimplePrediction(delayMinutes: 5, confidence: 0.8)
        XCTAssertFalse(lowDelay.isLikelyDelayed)
    }

    func testDelayPrediction_summaryText_onTime() {
        let onTime = makeSimplePrediction(delayMinutes: 0)
        XCTAssertEqual(onTime.summaryText, "Flight is expected to depart on time")
    }

    func testDelayPrediction_summaryText_delayed() {
        let delayed = makeSimplePrediction(delayMinutes: 25, confidence: 0.7)
        XCTAssertTrue(delayed.summaryText.contains("25 min delay"))
        XCTAssertTrue(delayed.summaryText.contains("Medium"))
    }

    // MARK: - DelayReason Tests

    func testDelayReason_iconNames() {
        XCTAssertEqual(DelayReason.lateAircraft.iconName, "airplane.circle")
        XCTAssertEqual(DelayReason.weather.iconName, "cloud.rain.fill")
        XCTAssertEqual(DelayReason.airportCongestion.iconName, "building.2.fill")
    }

    // MARK: - DelayFactor Tests

    func testDelayFactor_severityColors() {
        XCTAssertEqual(DelayFactor.Severity.low.color, "green")
        XCTAssertEqual(DelayFactor.Severity.medium.color, "yellow")
        XCTAssertEqual(DelayFactor.Severity.high.color, "red")
    }

    // MARK: - Helpers

    private func makeTestFlight(
        delayMinutes: Int,
        departureHour: Int,
        aircraft: Aircraft? = Aircraft(
            id: "N12345", registration: "N12345", icao24: "A12345",
            type: "B738", modelName: "Boeing 737-800",
            manufacturer: "Boeing", age: 5, airlineName: "United Airlines"
        )
    ) -> Flight {
        var calendar = Calendar.current
        calendar.timeZone = .current
        var depComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        depComponents.hour = departureHour
        depComponents.minute = 0
        let depTime = calendar.date(from: depComponents) ?? Date()

        return Flight(
            id: "TEST_\(departureHour)",
            flightNumber: "123",
            flightIata: "UA123",
            flightIcao: "UAL123",
            airline: Airline(id: "UA", name: "United Airlines", iataCode: "UA", icaoCode: "UAL", country: "US"),
            aircraft: aircraft,
            departure: FlightEndpoint(
                airportIata: "SFO", airportIcao: "KSFO",
                airportName: "San Francisco International",
                city: "San Francisco", country: "United States",
                timezone: "America/Los_Angeles",
                gate: "G92", terminal: "3", baggageClaim: nil,
                scheduledTime: depTime, estimatedTime: depTime.addingTimeInterval(Double(delayMinutes * 60)),
                actualTime: nil, delayMinutes: delayMinutes
            ),
            arrival: FlightEndpoint(
                airportIata: "JFK", airportIcao: "KJFK",
                airportName: "John F Kennedy International",
                city: "New York", country: "United States",
                timezone: "America/New_York",
                gate: "B22", terminal: "7", baggageClaim: nil,
                scheduledTime: depTime.addingTimeInterval(18000),
                estimatedTime: depTime.addingTimeInterval(18000 + Double(delayMinutes * 60)),
                actualTime: nil, delayMinutes: delayMinutes
            ),
            status: .scheduled,
            liveData: nil,
            lastUpdated: Date()
        )
    }

    private func makeSimplePrediction(
        delayMinutes: Int = 10,
        confidence: Double = 0.6
    ) -> DelayPrediction {
        DelayPrediction(
            flightId: "test",
            predictedDelayMinutes: delayMinutes,
            confidence: confidence,
            primaryReason: .lateAircraft,
            factors: [],
            inboundFlightId: nil,
            generatedAt: Date(),
            validUntil: Date().addingTimeInterval(1800)
        )
    }
}

// MARK: - Mock Airport Repository

final class MockAirportRepository: AirportRepositoryProtocol, @unchecked Sendable {
    var airportToReturn: Airport?
    var airportsToReturn: [Airport] = []
    var errorToThrow: AppError?

    func getAirport(code: String) async throws -> Airport? {
        if let error = errorToThrow { throw error }
        return airportToReturn
    }

    func searchAirports(query: String) async throws -> [Airport] {
        if let error = errorToThrow { throw error }
        return airportsToReturn
    }
}
