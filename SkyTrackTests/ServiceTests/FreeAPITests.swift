import XCTest
@testable import SkyTrack

// MARK: - ADSB Response Model Tests

final class ADSBResponseTests: XCTestCase {

    func testADSBAircraftDecoding() throws {
        let json = """
        {
            "hex": "a12345",
            "flight": "UAL123  ",
            "r": "N12345",
            "t": "B738",
            "lat": 37.7749,
            "lon": -122.4194,
            "alt_baro": 35000,
            "alt_geom": 35200,
            "gs": 450.5,
            "track": 270.5,
            "baro_rate": -512,
            "squawk": "1234",
            "category": "A3",
            "seen": 0.5,
            "seen_pos": 0.3,
            "messages": 1000,
            "rssi": -10.5
        }
        """.data(using: .utf8)!

        let aircraft = try JSONDecoder().decode(ADSBAircraft.self, from: json)

        XCTAssertEqual(aircraft.hex, "a12345")
        XCTAssertEqual(aircraft.flight, "UAL123  ")
        XCTAssertEqual(aircraft.r, "N12345")
        XCTAssertEqual(aircraft.t, "B738")
        XCTAssertEqual(aircraft.lat, 37.7749)
        XCTAssertEqual(aircraft.lon, -122.4194)
        XCTAssertEqual(aircraft.altBaro?.feetValue, 35000)
        XCTAssertFalse(aircraft.altBaro?.isGround ?? true)
        XCTAssertEqual(aircraft.altGeom, 35200)
        XCTAssertEqual(aircraft.gs, 450.5)
        XCTAssertEqual(aircraft.track, 270.5)
        XCTAssertEqual(aircraft.baroRate, -512)
        XCTAssertEqual(aircraft.squawk, "1234")
        XCTAssertEqual(aircraft.category, "A3")
    }

    func testAltitudeValue_ground() throws {
        let json = "\"ground\"".data(using: .utf8)!
        let alt = try JSONDecoder().decode(AltitudeValue.self, from: json)
        XCTAssertTrue(alt.isGround)
        XCTAssertEqual(alt.feetValue, 0)
    }

    func testAltitudeValue_feet() throws {
        let json = "35000".data(using: .utf8)!
        let alt = try JSONDecoder().decode(AltitudeValue.self, from: json)
        XCTAssertFalse(alt.isGround)
        XCTAssertEqual(alt.feetValue, 35000)
    }

    func testADSBResponseDecoding() throws {
        let json = """
        {
            "ac": [
                {
                    "hex": "a12345",
                    "flight": "UAL123  ",
                    "lat": 37.7749,
                    "lon": -122.4194,
                    "alt_baro": 35000,
                    "gs": 450.5,
                    "track": 270.5,
                    "baro_rate": 0,
                    "seen": 0.5
                }
            ],
            "msg": "No error",
            "now": 1740000000000,
            "total": 1,
            "ctime": 1740000000000,
            "ptime": 50
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ADSBResponse.self, from: json)

        XCTAssertEqual(response.ac?.count, 1)
        XCTAssertEqual(response.msg, "No error")
        XCTAssertEqual(response.total, 1)
    }

    func testADSBResponseToFlightPositions() throws {
        let json = """
        {
            "ac": [
                {
                    "hex": "a12345",
                    "flight": "UAL123  ",
                    "lat": 37.7749,
                    "lon": -122.4194,
                    "alt_baro": 35000,
                    "gs": 450.5,
                    "track": 270.5,
                    "baro_rate": -500,
                    "seen": 1.0
                },
                {
                    "hex": "b67890",
                    "flight": "DAL456  ",
                    "lat": 40.6413,
                    "lon": -73.7781,
                    "alt_baro": "ground",
                    "gs": 5.0,
                    "track": 90.0,
                    "baro_rate": 0,
                    "seen": 0.2
                }
            ],
            "now": 1740000000000,
            "total": 2
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ADSBResponse.self, from: json)
        let positions = response.toFlightPositions()

        XCTAssertEqual(positions.count, 2)

        let airborne = positions[0]
        XCTAssertEqual(airborne.id, "a12345")
        XCTAssertEqual(airborne.callsign, "UAL123")
        XCTAssertEqual(airborne.latitude, 37.7749)
        XCTAssertEqual(airborne.longitude, -122.4194)
        XCTAssertFalse(airborne.onGround)
        // 35000 feet → meters: 35000 * 0.3048 = 10668
        XCTAssertEqual(airborne.altitude, 10668.0, accuracy: 1.0)
        // 450.5 knots → m/s: 450.5 * 0.514444 ≈ 231.75
        XCTAssertEqual(airborne.velocity, 231.75, accuracy: 1.0)

        let grounded = positions[1]
        XCTAssertEqual(grounded.id, "b67890")
        XCTAssertEqual(grounded.callsign, "DAL456")
        XCTAssertTrue(grounded.onGround)
    }

    func testADSBResponse_emptyAircraftList() throws {
        let json = """
        {
            "ac": [],
            "msg": "No error",
            "now": 1740000000000,
            "total": 0
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ADSBResponse.self, from: json)
        let positions = response.toFlightPositions()
        XCTAssertTrue(positions.isEmpty)
    }

    func testADSBResponse_nullAircraftList() throws {
        let json = """
        {
            "msg": "No error",
            "now": 1740000000000,
            "total": 0
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ADSBResponse.self, from: json)
        let positions = response.toFlightPositions()
        XCTAssertTrue(positions.isEmpty)
    }

    func testADSBAircraftToFlight() {
        let aircraft = ADSBAircraft(
            hex: "a12345",
            flight: "UAL123  ",
            r: "N12345",
            t: "B738",
            lat: 37.7749,
            lon: -122.4194,
            altBaro: .feet(35000),
            altGeom: 35200,
            gs: 450.5,
            track: 270.5,
            baroRate: 0,
            geomRate: nil,
            navAltitudeMcp: nil,
            navHeading: nil,
            navQnh: nil,
            ias: nil, tas: nil, mach: nil,
            wd: nil, ws: nil, oat: nil, tat: nil,
            squawk: nil, emergency: nil, category: nil,
            nic: nil, rc: nil, seenPos: nil, seen: nil,
            messages: nil, rssi: nil,
            alert: nil, spi: nil, dbFlags: nil
        )

        let airportDB = LocalAirportDatabase()
        let airlineDB = LocalAirlineDatabase()

        let flight = aircraft.toFlight(airportDB: airportDB, airlineDB: airlineDB)
        XCTAssertNotNil(flight)
        XCTAssertEqual(flight?.flightNumber, "UAL123")
        XCTAssertNotNil(flight?.airline)
        XCTAssertEqual(flight?.airline?.name, "United Airlines")
        XCTAssertEqual(flight?.aircraft?.registration, "N12345")
        XCTAssertEqual(flight?.aircraft?.type, "B738")
        XCTAssertEqual(flight?.status, .active)
    }
}

// MARK: - Local Airport Database Tests

final class LocalAirportDatabaseTests: XCTestCase {

    let db = LocalAirportDatabase()

    func testLookupByIATA() {
        let sfo = db.getAirport(code: "SFO")
        XCTAssertNotNil(sfo)
        XCTAssertEqual(sfo?.iataCode, "SFO")
        XCTAssertEqual(sfo?.icaoCode, "KSFO")
        XCTAssertEqual(sfo?.city, "San Francisco")
        XCTAssertEqual(sfo?.country, "United States")
        XCTAssertEqual(sfo?.latitude, 37.6213, accuracy: 0.01)
    }

    func testLookupByICAO() {
        let jfk = db.getAirport(code: "KJFK")
        XCTAssertNotNil(jfk)
        XCTAssertEqual(jfk?.iataCode, "JFK")
        XCTAssertEqual(jfk?.name, "John F. Kennedy International Airport")
    }

    func testLookupCaseInsensitive() {
        let lhr = db.getAirport(code: "lhr")
        XCTAssertNotNil(lhr)
        XCTAssertEqual(lhr?.iataCode, "LHR")
    }

    func testLookupNonExistent() {
        let result = db.getAirport(code: "ZZZ")
        XCTAssertNil(result)
    }

    func testSearchByCity() {
        let results = db.searchAirports(query: "Tokyo")
        XCTAssertGreaterThanOrEqual(results.count, 2) // HND + NRT
        XCTAssertTrue(results.contains { $0.iataCode == "HND" })
        XCTAssertTrue(results.contains { $0.iataCode == "NRT" })
    }

    func testSearchByName() {
        let results = db.searchAirports(query: "Heathrow")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.iataCode, "LHR")
    }

    func testSearchByCountry() {
        let results = db.searchAirports(query: "Australia")
        XCTAssertGreaterThanOrEqual(results.count, 4)
    }

    func testSearchTooShort() {
        let results = db.searchAirports(query: "A")
        XCTAssertTrue(results.isEmpty)
    }

    func testNearbyAirports() {
        // Near JFK (40.6413, -73.7781)
        let nearby = db.nearbyAirports(latitude: 40.6413, longitude: -73.7781, radiusKM: 50)
        XCTAssertGreaterThanOrEqual(nearby.count, 2) // JFK + LGA + EWR within 50km
        XCTAssertEqual(nearby.first?.iataCode, "JFK") // Closest should be JFK itself
    }

    func testMajorAirportsCovered() {
        let majorCodes = ["ATL", "LAX", "ORD", "DFW", "DEN", "JFK", "SFO", "SEA",
                          "LHR", "CDG", "AMS", "FRA", "IST", "DXB", "SIN", "HKG",
                          "NRT", "ICN", "SYD", "GRU", "MEX", "YYZ", "PEK"]

        for code in majorCodes {
            XCTAssertNotNil(db.getAirport(code: code), "Missing major airport: \(code)")
        }
    }
}

// MARK: - Local Airline Database Tests

final class LocalAirlineDatabaseTests: XCTestCase {

    let db = LocalAirlineDatabase()

    func testLookupByIATA() {
        let ua = db.getAirline(code: "UA")
        XCTAssertNotNil(ua)
        XCTAssertEqual(ua?.name, "United Airlines")
        XCTAssertEqual(ua?.icaoCode, "UAL")
    }

    func testLookupByICAO() {
        let baw = db.getAirline(code: "BAW")
        XCTAssertNotNil(baw)
        XCTAssertEqual(baw?.name, "British Airways")
        XCTAssertEqual(baw?.iataCode, "BA")
    }

    func testLookupCaseInsensitive() {
        let dl = db.getAirline(code: "dl")
        XCTAssertNotNil(dl)
        XCTAssertEqual(dl?.name, "Delta Air Lines")
    }

    func testAirlineFromCallsign_ICAO() {
        // ADS-B callsigns typically use 3-letter ICAO prefix
        let ua = db.airlineFromCallsign("UAL123")
        XCTAssertNotNil(ua)
        XCTAssertEqual(ua?.name, "United Airlines")

        let dl = db.airlineFromCallsign("DAL456")
        XCTAssertNotNil(dl)
        XCTAssertEqual(dl?.name, "Delta Air Lines")

        let ba = db.airlineFromCallsign("BAW789")
        XCTAssertNotNil(ba)
        XCTAssertEqual(ba?.name, "British Airways")
    }

    func testAirlineFromCallsign_short() {
        let result = db.airlineFromCallsign("AB")
        XCTAssertNil(result) // Too short
    }

    func testAirlineFromCallsign_unknown() {
        let result = db.airlineFromCallsign("ZZZ999")
        XCTAssertNil(result)
    }

    func testSearchByName() {
        let results = db.searchAirlines(query: "United")
        XCTAssertTrue(results.contains { $0.name == "United Airlines" })
    }

    func testSearchByCountry() {
        let results = db.searchAirlines(query: "Japan")
        XCTAssertGreaterThanOrEqual(results.count, 2) // ANA + JAL
    }

    func testMajorAirlinesCovered() {
        let majors = ["AA", "DL", "UA", "WN", "BA", "LH", "AF", "EK", "QR",
                      "SQ", "QF", "CX", "NH", "KE", "TK", "FR", "AC", "LA"]

        for code in majors {
            XCTAssertNotNil(db.getAirline(code: code), "Missing major airline: \(code)")
        }
    }
}

// MARK: - Configuration Tests (Free API)

final class FreeAPIConfigurationTests: XCTestCase {

    func testNoAPIKeyRequired() {
        // Configuration should not require any API keys
        // Just verify the URLs are valid
        XCTAssertNotNil(Configuration.adsbLolBaseURL)
        XCTAssertNotNil(Configuration.adsbOneBaseURL)
        XCTAssertNotNil(Configuration.openSkyBaseURL)
    }

    func testADSBLolURL() {
        XCTAssertEqual(Configuration.adsbLolBaseURL.host, "api.adsb.lol")
    }

    func testADSBOneURL() {
        XCTAssertEqual(Configuration.adsbOneBaseURL.host, "api.adsb.one")
    }

    func testOpenSkyURL() {
        XCTAssertEqual(Configuration.openSkyBaseURL.host, "opensky-network.org")
    }

    func testDataSourcesInfo() {
        XCTAssertTrue(Configuration.dataSources.contains("ADSB.lol"))
        XCTAssertTrue(Configuration.dataSources.contains("ADSB.One"))
        XCTAssertTrue(Configuration.dataSources.contains("OpenSky"))
        XCTAssertTrue(Configuration.dataSources.contains("Local Database"))
    }
}

// MARK: - Repository Integration Tests

final class FreeAPIRepositoryTests: XCTestCase {

    func testAirportRepository_usesLocalDB() async throws {
        let repo = AirportRepository()

        let sfo = try await repo.getAirport(code: "SFO")
        XCTAssertNotNil(sfo)
        XCTAssertEqual(sfo?.iataCode, "SFO")
        XCTAssertEqual(sfo?.name, "San Francisco International Airport")
    }

    func testAirportRepository_searchWorks() async throws {
        let repo = AirportRepository()

        let results = try await repo.searchAirports(query: "London")
        XCTAssertGreaterThanOrEqual(results.count, 2) // LHR, LGW, STN
    }

    func testAirportRepository_shortQueryReturnsEmpty() async throws {
        let repo = AirportRepository()

        let results = try await repo.searchAirports(query: "L")
        XCTAssertTrue(results.isEmpty)
    }
}
