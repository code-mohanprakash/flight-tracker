import Foundation

struct Aircraft: Identifiable, Codable, Hashable {
    let id: String
    let registration: String?
    let icao24: String?
    let type: String?
    let modelName: String?
    let manufacturer: String?
    let age: Int?
    let airlineName: String?

    var displayType: String {
        if let modelName { return modelName }
        if let type { return type }
        return "Unknown Aircraft"
    }

    var displayRegistration: String {
        registration ?? icao24 ?? "Unknown"
    }
}
