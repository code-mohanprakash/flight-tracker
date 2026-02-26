import Foundation

struct Airline: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let iataCode: String?
    let icaoCode: String?
    let country: String?

    var displayCode: String {
        iataCode ?? icaoCode ?? id
    }
}
