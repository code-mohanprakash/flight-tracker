import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

struct APIEndpoint {
    let path: String
    let method: HTTPMethod
    let queryItems: [URLQueryItem]?

    init(path: String, method: HTTPMethod = .get, queryItems: [URLQueryItem]? = nil) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
    }
}

// MARK: - AviationStack Endpoints
enum AviationStackEndpoints {
    static func flights(flightIata: String? = nil, depIata: String? = nil, arrIata: String? = nil, airlineIata: String? = nil, flightStatus: String? = nil) -> APIEndpoint {
        var items: [URLQueryItem] = []
        if let flightIata { items.append(.init(name: "flight_iata", value: flightIata)) }
        if let depIata { items.append(.init(name: "dep_iata", value: depIata)) }
        if let arrIata { items.append(.init(name: "arr_iata", value: arrIata)) }
        if let airlineIata { items.append(.init(name: "airline_iata", value: airlineIata)) }
        if let flightStatus { items.append(.init(name: "flight_status", value: flightStatus)) }
        return APIEndpoint(path: "flights", queryItems: items)
    }

    static func flightByNumber(_ flightNumber: String) -> APIEndpoint {
        flights(flightIata: flightNumber)
    }

    static func departures(airportCode: String) -> APIEndpoint {
        flights(depIata: airportCode)
    }

    static func arrivals(airportCode: String) -> APIEndpoint {
        flights(arrIata: airportCode)
    }

    static func airports(search: String? = nil, iataCode: String? = nil) -> APIEndpoint {
        var items: [URLQueryItem] = []
        if let search { items.append(.init(name: "search", value: search)) }
        if let iataCode { items.append(.init(name: "iata_code", value: iataCode)) }
        return APIEndpoint(path: "airports", queryItems: items)
    }

    static func airlines(search: String? = nil, iataCode: String? = nil) -> APIEndpoint {
        var items: [URLQueryItem] = []
        if let search { items.append(.init(name: "search", value: search)) }
        if let iataCode { items.append(.init(name: "iata_code", value: iataCode)) }
        return APIEndpoint(path: "airlines", queryItems: items)
    }
}
