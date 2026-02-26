import XCTest
@testable import SkyTrack

final class APIModelMapperTests: XCTestCase {

    // MARK: - Flight Mapping

    func testMapFlight_withCompleteData() throws {
        let asFlight = createTestASFlight()
        let flight = APIModelMapper.mapFlight(asFlight)

        XCTAssertEqual(flight.flightIata, "UA123")
        XCTAssertEqual(flight.flightIcao, "UAL123")
        XCTAssertEqual(flight.flightNumber, "123")
        XCTAssertEqual(flight.status, .active)
    }

    func testMapFlight_departureEndpoint() throws {
        let asFlight = createTestASFlight()
        let flight = APIModelMapper.mapFlight(asFlight)

        XCTAssertEqual(flight.departure.airportIata, "SFO")
        XCTAssertEqual(flight.departure.airportIcao, "KSFO")
        XCTAssertEqual(flight.departure.gate, "G92")
        XCTAssertEqual(flight.departure.terminal, "3")
        XCTAssertEqual(flight.departure.delayMinutes, 15)
    }

    func testMapFlight_arrivalEndpoint() throws {
        let asFlight = createTestASFlight()
        let flight = APIModelMapper.mapFlight(asFlight)

        XCTAssertEqual(flight.arrival.airportIata, "JFK")
        XCTAssertEqual(flight.arrival.gate, "B22")
        XCTAssertEqual(flight.arrival.terminal, "7")
        XCTAssertEqual(flight.arrival.baggageClaim, "4")
    }

    func testMapFlight_airline() throws {
        let asFlight = createTestASFlight()
        let flight = APIModelMapper.mapFlight(asFlight)

        XCTAssertNotNil(flight.airline)
        XCTAssertEqual(flight.airline?.name, "United Airlines")
        XCTAssertEqual(flight.airline?.iataCode, "UA")
    }

    func testMapFlight_aircraft() throws {
        let asFlight = createTestASFlight()
        let flight = APIModelMapper.mapFlight(asFlight)

        XCTAssertNotNil(flight.aircraft)
        XCTAssertEqual(flight.aircraft?.registration, "N12345")
        XCTAssertEqual(flight.aircraft?.icao24, "A12345")
    }

    func testMapFlight_liveData() throws {
        let asFlight = createTestASFlight()
        let flight = APIModelMapper.mapFlight(asFlight)

        XCTAssertNotNil(flight.liveData)
        XCTAssertEqual(flight.liveData?.latitude, 39.5)
        XCTAssertEqual(flight.liveData?.longitude, -98.35)
        XCTAssertEqual(flight.liveData?.altitude, 10972.8)
        XCTAssertEqual(flight.liveData?.heading, 85.0)
        XCTAssertEqual(flight.liveData?.isGround, false)
    }

    func testMapFlight_statusMapping() {
        let statuses: [(String?, FlightStatus)] = [
            ("scheduled", .scheduled),
            ("active", .active),
            ("landed", .landed),
            ("cancelled", .cancelled),
            ("diverted", .diverted),
            ("incident", .incident),
            (nil, .unknown),
            ("invalid", .unknown),
        ]

        for (input, expected) in statuses {
            let asFlight = AviationStackFlight(
                flightDate: nil, flightStatus: input,
                departure: nil, arrival: nil, airline: nil,
                flight: nil, aircraft: nil, live: nil
            )
            let flight = APIModelMapper.mapFlight(asFlight)
            XCTAssertEqual(flight.status, expected, "Status '\(input ?? "nil")' should map to \(expected)")
        }
    }

    // MARK: - Airport Mapping

    func testMapAirport_withCompleteData() {
        let asAirport = AviationStackAirport(
            airportName: "San Francisco International",
            iataCode: "SFO",
            icaoCode: "KSFO",
            latitude: "37.6213",
            longitude: "-122.379",
            geonameCityId: "5391959",
            timezone: "America/Los_Angeles",
            gmt: "-8",
            countryName: "United States",
            countryIso2: "US",
            cityIataCode: "SFO",
            phoneNumber: nil
        )

        let airport = APIModelMapper.mapAirport(asAirport)

        XCTAssertEqual(airport.iataCode, "SFO")
        XCTAssertEqual(airport.icaoCode, "KSFO")
        XCTAssertEqual(airport.name, "San Francisco International")
        XCTAssertEqual(airport.latitude, 37.6213, accuracy: 0.001)
        XCTAssertEqual(airport.longitude, -122.379, accuracy: 0.001)
        XCTAssertEqual(airport.timezone, "America/Los_Angeles")
        XCTAssertEqual(airport.country, "United States")
    }

    // MARK: - Multiple Flights

    func testMapFlights_array() {
        let flights = [createTestASFlight(), createTestASFlight()]
        let mapped = APIModelMapper.mapFlights(flights)
        XCTAssertEqual(mapped.count, 2)
    }

    // MARK: - Helpers

    private func createTestASFlight() -> AviationStackFlight {
        AviationStackFlight(
            flightDate: "2026-02-26",
            flightStatus: "active",
            departure: .init(
                airport: "San Francisco International",
                timezone: "America/Los_Angeles",
                iata: "SFO", icao: "KSFO",
                terminal: "3", gate: "G92",
                delay: 15,
                scheduled: "2026-02-26T08:00:00+00:00",
                estimated: "2026-02-26T08:15:00+00:00",
                actual: "2026-02-26T08:15:00+00:00"
            ),
            arrival: .init(
                airport: "John F Kennedy International",
                timezone: "America/New_York",
                iata: "JFK", icao: "KJFK",
                terminal: "7", gate: "B22",
                baggage: "4", delay: 10,
                scheduled: "2026-02-26T16:30:00+00:00",
                estimated: "2026-02-26T16:40:00+00:00",
                actual: nil
            ),
            airline: .init(name: "United Airlines", iata: "UA", icao: "UAL"),
            flight: .init(number: "123", iata: "UA123", icao: "UAL123"),
            aircraft: .init(registration: "N12345", iata: "B738", icao: "B738", icao24: "A12345"),
            live: .init(
                updated: "2026-02-26T12:00:00+00:00",
                latitude: 39.5, longitude: -98.35,
                altitude: 10972.8, direction: 85.0,
                speedHorizontal: 870.0, speedVertical: 0.0,
                isGround: false
            )
        )
    }
}
