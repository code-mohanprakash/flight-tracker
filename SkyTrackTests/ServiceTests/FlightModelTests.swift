import XCTest
@testable import SkyTrack

final class FlightModelTests: XCTestCase {

    // MARK: - Flight Tests

    func testFlight_displayName() {
        let flight = TestData.sampleFlight
        XCTAssertEqual(flight.displayName, "UA123")
    }

    func testFlight_routeDescription() {
        let flight = TestData.sampleFlight
        XCTAssertEqual(flight.routeDescription, "SFO → JFK")
    }

    func testFlight_delayMinutes() {
        let flight = TestData.sampleFlight
        XCTAssertEqual(flight.delayMinutes, 15)
    }

    func testFlight_progress_active() {
        let flight = TestData.sampleFlight
        XCTAssertNotNil(flight.progress)
        if let progress = flight.progress {
            XCTAssertGreaterThanOrEqual(progress, 0)
            XCTAssertLessThanOrEqual(progress, 1)
        }
    }

    func testFlight_progress_landed() {
        let landed = Flight(
            id: "test", flightNumber: "123",
            flightIata: "UA123", flightIcao: nil,
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
        XCTAssertEqual(landed.progress, 1.0)
    }

    // MARK: - FlightStatus Tests

    func testFlightStatus_displayName() {
        XCTAssertEqual(FlightStatus.scheduled.displayName, "Scheduled")
        XCTAssertEqual(FlightStatus.active.displayName, "In Air")
        XCTAssertEqual(FlightStatus.landed.displayName, "Landed")
        XCTAssertEqual(FlightStatus.cancelled.displayName, "Cancelled")
        XCTAssertEqual(FlightStatus.diverted.displayName, "Diverted")
    }

    func testFlightStatus_isActive() {
        XCTAssertTrue(FlightStatus.active.isActive)
        XCTAssertFalse(FlightStatus.scheduled.isActive)
        XCTAssertFalse(FlightStatus.landed.isActive)
    }

    func testFlightStatus_isTerminal() {
        XCTAssertTrue(FlightStatus.landed.isTerminal)
        XCTAssertTrue(FlightStatus.cancelled.isTerminal)
        XCTAssertFalse(FlightStatus.active.isTerminal)
        XCTAssertFalse(FlightStatus.scheduled.isTerminal)
    }

    // MARK: - FlightEndpoint Tests

    func testFlightEndpoint_isDelayed() {
        let delayed = FlightEndpoint(
            airportIata: "SFO", airportIcao: nil, airportName: nil,
            city: nil, country: nil, timezone: nil,
            gate: nil, terminal: nil, baggageClaim: nil,
            scheduledTime: nil, estimatedTime: nil, actualTime: nil,
            delayMinutes: 30
        )
        XCTAssertTrue(delayed.isDelayed)

        let onTime = FlightEndpoint(
            airportIata: "SFO", airportIcao: nil, airportName: nil,
            city: nil, country: nil, timezone: nil,
            gate: nil, terminal: nil, baggageClaim: nil,
            scheduledTime: nil, estimatedTime: nil, actualTime: nil,
            delayMinutes: 0
        )
        XCTAssertFalse(onTime.isDelayed)
    }

    // MARK: - LiveFlightData Tests

    func testLiveFlightData_altitudeFeet() {
        let live = TestData.sampleFlight.liveData!
        // 10972.8m = ~36,000 ft
        XCTAssertEqual(live.altitudeFeet, 36001, accuracy: 10)
    }

    func testLiveFlightData_speedKnots() {
        let live = TestData.sampleFlight.liveData!
        // 870 km/h ≈ 470 knots
        XCTAssertEqual(live.speedKnots, 469, accuracy: 5)
    }

    // MARK: - FlightPosition Tests

    func testFlightPosition_cleanCallsign() {
        let pos = TestData.samplePosition
        XCTAssertEqual(pos.cleanCallsign, "UAL123")
    }

    func testFlightPosition_altitudeFeet() {
        let pos = TestData.samplePosition
        XCTAssertEqual(pos.altitudeFeet, 36001, accuracy: 10)
    }

    // MARK: - SavedFlight Tests

    func testSavedFlight_id_uniqueness() {
        let f1 = SavedFlight(flightNumber: "UA123", date: Date())
        let f2 = SavedFlight(flightNumber: "UA123", date: Date())
        let f3 = SavedFlight(flightNumber: "DL456", date: Date())

        XCTAssertEqual(f1.id, f2.id) // Same flight same date
        XCTAssertNotEqual(f1.id, f3.id) // Different flight
    }
}
