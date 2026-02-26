import Foundation

enum APIModelMapper {
    // MARK: - Flight Mapping

    static func mapFlight(_ asFlight: AviationStackFlight) -> Flight {
        let flightNumber = asFlight.flight?.iata ?? asFlight.flight?.icao ?? asFlight.flight?.number ?? "Unknown"

        return Flight(
            id: "\(flightNumber)_\(asFlight.flightDate ?? "")",
            flightNumber: asFlight.flight?.number ?? "Unknown",
            flightIata: asFlight.flight?.iata,
            flightIcao: asFlight.flight?.icao,
            airline: mapAirline(asFlight.airline),
            aircraft: mapAircraft(asFlight.aircraft),
            departure: mapDeparture(asFlight.departure),
            arrival: mapArrival(asFlight.arrival),
            status: mapStatus(asFlight.flightStatus),
            liveData: mapLiveData(asFlight.live),
            lastUpdated: Date()
        )
    }

    static func mapFlights(_ asFlights: [AviationStackFlight]) -> [Flight] {
        asFlights.map(mapFlight)
    }

    // MARK: - Departure/Arrival Mapping

    private static func mapDeparture(_ dep: AviationStackFlight.ASDeparture?) -> FlightEndpoint {
        FlightEndpoint(
            airportIata: dep?.iata,
            airportIcao: dep?.icao,
            airportName: dep?.airport,
            city: nil,
            country: nil,
            timezone: dep?.timezone,
            gate: dep?.gate,
            terminal: dep?.terminal,
            baggageClaim: nil,
            scheduledTime: Date.from(isoString: dep?.scheduled),
            estimatedTime: Date.from(isoString: dep?.estimated),
            actualTime: Date.from(isoString: dep?.actual),
            delayMinutes: dep?.delay
        )
    }

    private static func mapArrival(_ arr: AviationStackFlight.ASArrival?) -> FlightEndpoint {
        FlightEndpoint(
            airportIata: arr?.iata,
            airportIcao: arr?.icao,
            airportName: arr?.airport,
            city: nil,
            country: nil,
            timezone: arr?.timezone,
            gate: arr?.gate,
            terminal: arr?.terminal,
            baggageClaim: arr?.baggage,
            scheduledTime: Date.from(isoString: arr?.scheduled),
            estimatedTime: Date.from(isoString: arr?.estimated),
            actualTime: Date.from(isoString: arr?.actual),
            delayMinutes: arr?.delay
        )
    }

    // MARK: - Status Mapping

    private static func mapStatus(_ status: String?) -> FlightStatus {
        switch status?.lowercased() {
        case "scheduled": return .scheduled
        case "active": return .active
        case "landed": return .landed
        case "cancelled": return .cancelled
        case "diverted": return .diverted
        case "incident": return .incident
        default: return .unknown
        }
    }

    // MARK: - Airline Mapping

    private static func mapAirline(_ as: AviationStackFlight.ASAirline?) -> Airline? {
        guard let airline = `as`, airline.name != nil else { return nil }
        return Airline(
            id: airline.iata ?? airline.icao ?? UUID().uuidString,
            name: airline.name ?? "Unknown",
            iataCode: airline.iata,
            icaoCode: airline.icao,
            country: nil
        )
    }

    // MARK: - Aircraft Mapping

    private static func mapAircraft(_ asAircraft: AviationStackFlight.ASAircraft?) -> Aircraft? {
        guard let ac = asAircraft else { return nil }
        return Aircraft(
            id: ac.registration ?? ac.icao24 ?? UUID().uuidString,
            registration: ac.registration,
            icao24: ac.icao24,
            type: ac.iata,
            modelName: nil,
            manufacturer: nil,
            age: nil,
            airlineName: nil
        )
    }

    // MARK: - Live Data Mapping

    private static func mapLiveData(_ live: AviationStackFlight.ASLive?) -> LiveFlightData? {
        guard let live, let lat = live.latitude, let lon = live.longitude else { return nil }
        return LiveFlightData(
            latitude: lat,
            longitude: lon,
            altitude: live.altitude ?? 0,
            speed: live.speedHorizontal ?? 0,
            heading: live.direction ?? 0,
            verticalSpeed: live.speedVertical ?? 0,
            isGround: live.isGround ?? false,
            updated: Date.from(isoString: live.updated) ?? Date()
        )
    }

    // MARK: - Airport Mapping

    static func mapAirport(_ asAirport: AviationStackAirport) -> Airport {
        Airport(
            id: asAirport.iataCode ?? asAirport.icaoCode ?? UUID().uuidString,
            iataCode: asAirport.iataCode,
            icaoCode: asAirport.icaoCode,
            name: asAirport.airportName ?? "Unknown Airport",
            city: nil,
            country: asAirport.countryName,
            countryCode: asAirport.countryIso2,
            latitude: Double(asAirport.latitude ?? "0") ?? 0,
            longitude: Double(asAirport.longitude ?? "0") ?? 0,
            timezone: asAirport.timezone,
            altitude: nil
        )
    }

    static func mapAirports(_ asAirports: [AviationStackAirport]) -> [Airport] {
        asAirports.map(mapAirport)
    }
}
