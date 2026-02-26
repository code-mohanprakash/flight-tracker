import SwiftUI

/// Friends tracking system — invite friends to track your flights in real-time.
@Observable
final class FriendsTrackingService {
    var friends: [Friend] = []
    var sharedFlights: [SharedFlight] = []

    private static let friendsKey = "skytrack_friends"
    private static let sharedFlightsKey = "skytrack_shared_flights"

    init() {
        loadFriends()
        loadSharedFlights()
    }

    // MARK: - Friend Management

    func addFriend(_ friend: Friend) {
        friends.append(friend)
        saveFriends()
    }

    func removeFriend(id: String) {
        friends.removeAll { $0.id == id }
        sharedFlights.removeAll { $0.friendId == id }
        saveFriends()
        saveSharedFlights()
    }

    func generateInviteLink() -> URL? {
        let code = UUID().uuidString.prefix(8).lowercased()
        return URL(string: "skytrack://invite/\(code)")
    }

    // MARK: - Flight Sharing

    func shareFlight(_ flightNumber: String, date: Date, withFriendIds friendIds: [String]) {
        for friendId in friendIds {
            let shared = SharedFlight(
                flightNumber: flightNumber,
                date: date,
                friendId: friendId,
                sharedAt: Date()
            )
            sharedFlights.append(shared)
        }
        saveSharedFlights()
    }

    func stopSharingFlight(_ flightNumber: String, withFriendId friendId: String) {
        sharedFlights.removeAll {
            $0.flightNumber == flightNumber && $0.friendId == friendId
        }
        saveSharedFlights()
    }

    func flightsSharedWithMe() -> [SharedFlight] {
        sharedFlights.filter { $0.direction == .incoming }
    }

    func mySharedFlights() -> [SharedFlight] {
        sharedFlights.filter { $0.direction == .outgoing }
    }

    // MARK: - Pickup Countdown

    func pickupCountdown(for flight: Flight) -> PickupInfo? {
        guard flight.status == .active || flight.status == .landed else { return nil }

        let arrivalTime = flight.arrival.estimatedTime ?? flight.arrival.scheduledTime
        guard let eta = arrivalTime else { return nil }

        let baggageWait: TimeInterval = 15 * 60 // 15 min estimate
        let pickupTime = eta.addingTimeInterval(baggageWait)
        let remaining = pickupTime.timeIntervalSinceNow

        return PickupInfo(
            flight: flight,
            estimatedArrival: eta,
            estimatedPickupTime: pickupTime,
            remainingSeconds: max(0, remaining),
            baggageClaim: flight.arrival.baggageClaim
        )
    }

    // MARK: - Persistence

    private func saveFriends() {
        if let data = try? JSONEncoder().encode(friends) {
            UserDefaults.standard.set(data, forKey: Self.friendsKey)
        }
    }

    private func loadFriends() {
        guard let data = UserDefaults.standard.data(forKey: Self.friendsKey),
              let decoded = try? JSONDecoder().decode([Friend].self, from: data) else { return }
        friends = decoded
    }

    private func saveSharedFlights() {
        if let data = try? JSONEncoder().encode(sharedFlights) {
            UserDefaults.standard.set(data, forKey: Self.sharedFlightsKey)
        }
    }

    private func loadSharedFlights() {
        guard let data = UserDefaults.standard.data(forKey: Self.sharedFlightsKey),
              let decoded = try? JSONDecoder().decode([SharedFlight].self, from: data) else { return }
        sharedFlights = decoded
    }
}

// MARK: - Models

struct Friend: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let avatarEmoji: String
    let addedAt: Date
    var isActive: Bool

    init(name: String, avatarEmoji: String = "👤") {
        self.id = UUID().uuidString
        self.name = name
        self.avatarEmoji = avatarEmoji
        self.addedAt = Date()
        self.isActive = true
    }
}

struct SharedFlight: Identifiable, Codable {
    let id: String
    let flightNumber: String
    let date: Date
    let friendId: String
    let sharedAt: Date
    var direction: ShareDirection

    init(flightNumber: String, date: Date, friendId: String, sharedAt: Date, direction: ShareDirection = .outgoing) {
        self.id = UUID().uuidString
        self.flightNumber = flightNumber
        self.date = date
        self.friendId = friendId
        self.sharedAt = sharedAt
        self.direction = direction
    }

    enum ShareDirection: String, Codable {
        case outgoing  // I shared with friend
        case incoming  // Friend shared with me
    }
}

struct PickupInfo {
    let flight: Flight
    let estimatedArrival: Date
    let estimatedPickupTime: Date
    let remainingSeconds: TimeInterval
    let baggageClaim: String?

    var formattedCountdown: String {
        let minutes = Int(remainingSeconds) / 60
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }

    var isArrived: Bool {
        flight.status == .landed
    }
}
