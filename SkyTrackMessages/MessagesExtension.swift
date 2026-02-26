import SwiftUI
import Messages

/// iMessage extension for sharing flight status cards inline in conversations.
class MessagesViewController: MSMessagesAppViewController {

    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        presentFlightPicker()
    }

    private func presentFlightPicker() {
        let hostingController = UIHostingController(
            rootView: MessageFlightPickerView(
                onSelect: { [weak self] flight in
                    self?.sendFlightMessage(flight)
                }
            )
        )

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        hostingController.didMove(toParent: self)
    }

    private func sendFlightMessage(_ flight: MessageFlight) {
        guard let conversation = activeConversation else { return }

        let layout = MSMessageTemplateLayout()
        layout.caption = "\(flight.flightNumber) — \(flight.statusText)"
        layout.subcaption = "\(flight.origin) → \(flight.destination)"
        layout.trailingCaption = flight.departureTime
        layout.trailingSubcaption = flight.gate.map { "Gate \($0)" }
        layout.imageTitle = flight.flightNumber

        let message = MSMessage(session: conversation.selectedMessage?.session ?? MSSession())
        message.layout = layout
        message.summaryText = "\(flight.flightNumber): \(flight.origin) → \(flight.destination)"

        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "flight", value: flight.flightNumber),
            URLQueryItem(name: "date", value: flight.dateString),
        ]
        message.url = components.url

        conversation.insert(message) { error in
            if let error {
                print("Failed to send message: \(error)")
            }
        }
    }
}

// MARK: - Message Flight Model

struct MessageFlight: Identifiable {
    let id = UUID()
    let flightNumber: String
    let origin: String
    let destination: String
    let statusText: String
    let departureTime: String
    let gate: String?
    let dateString: String
}

// MARK: - SwiftUI Views for iMessage

struct MessageFlightPickerView: View {
    let onSelect: (MessageFlight) -> Void
    @State private var savedFlights: [MessageFlight] = []

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "airplane.circle.fill")
                    .foregroundStyle(.blue)
                Text("Share Flight")
                    .font(.headline)
                Spacer()
            }
            .padding()

            if savedFlights.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "airplane")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No saved flights")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Add flights in the SkyTrack app")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(savedFlights) { flight in
                            Button { onSelect(flight) } label: {
                                MessageFlightCard(flight: flight)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .onAppear(perform: loadFlights)
    }

    private func loadFlights() {
        // Load from shared UserDefaults (App Group)
        guard let defaults = UserDefaults(suiteName: "group.com.skytrack.shared"),
              let data = defaults.data(forKey: "saved_flights"),
              let flights = try? JSONDecoder().decode([SavedFlightDTO].self, from: data) else {
            return
        }

        savedFlights = flights.map { dto in
            MessageFlight(
                flightNumber: dto.flightNumber,
                origin: dto.origin ?? "???",
                destination: dto.destination ?? "???",
                statusText: dto.status ?? "Scheduled",
                departureTime: dto.departureTime ?? "",
                gate: dto.gate,
                dateString: dto.dateString
            )
        }
    }
}

struct MessageFlightCard: View {
    let flight: MessageFlight

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(flight.flightNumber)
                    .font(.subheadline.weight(.bold).monospaced())
                Text("\(flight.origin) → \(flight.destination)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(flight.statusText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.blue)
                Text(flight.departureTime)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Shared DTO

struct SavedFlightDTO: Codable {
    let flightNumber: String
    let origin: String?
    let destination: String?
    let status: String?
    let departureTime: String?
    let gate: String?
    let dateString: String
}
