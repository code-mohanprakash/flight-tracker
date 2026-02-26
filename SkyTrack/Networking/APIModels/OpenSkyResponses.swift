import Foundation

struct OpenSkyStatesResponse: Decodable {
    let time: Int
    let states: [[OpenSkyStateValue]]?

    struct OpenSkyStateValue: Decodable {
        let value: Any

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let string = try? container.decode(String.self) {
                value = string
            } else if let double = try? container.decode(Double.self) {
                value = double
            } else if let int = try? container.decode(Int.self) {
                value = int
            } else if let bool = try? container.decode(Bool.self) {
                value = bool
            } else if container.decodeNil() {
                value = NSNull()
            } else {
                value = ""
            }
        }

        var stringValue: String? { value as? String }
        var doubleValue: Double? { value as? Double }
        var intValue: Int? { value as? Int }
        var boolValue: Bool? { value as? Bool }
    }
}

extension OpenSkyStatesResponse {
    func toFlightPositions() -> [FlightPosition] {
        guard let states else { return [] }
        return states.compactMap { state in
            guard state.count >= 17,
                  let icao24 = state[0].stringValue,
                  let lat = state[6].doubleValue,
                  let lon = state[5].doubleValue else {
                return nil
            }

            let callsign = state[1].stringValue?.trimmingCharacters(in: .whitespaces)
            let altitude = state[7].doubleValue ?? state[13].doubleValue ?? 0
            let velocity = state[9].doubleValue ?? 0
            let trueTrack = state[10].doubleValue ?? 0
            let verticalRate = state[11].doubleValue ?? 0
            let onGround = state[8].boolValue ?? false
            let lastContact = state[4].doubleValue ?? Double(time)
            let originCountry = state[2].stringValue

            guard lat != 0 || lon != 0 else { return nil }

            return FlightPosition(
                id: icao24,
                callsign: callsign,
                latitude: lat,
                longitude: lon,
                altitude: altitude,
                velocity: velocity,
                trueTrack: trueTrack,
                verticalRate: verticalRate,
                onGround: onGround,
                lastUpdate: Date(timeIntervalSince1970: lastContact),
                originCountry: originCountry
            )
        }
    }
}
