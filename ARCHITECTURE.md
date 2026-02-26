# SkyTrack — iOS Architecture & Technical Specification

## Technology Stack

| Layer | Technology | Version | Purpose |
|-------|-----------|---------|---------|
| Language | Swift | 5.9+ | Primary language |
| UI | SwiftUI | iOS 17+ | All user interfaces |
| Architecture | MVVM + Clean Architecture | — | Separation of concerns |
| Maps | MapKit for SwiftUI | iOS 17+ | Flight map, airport maps |
| AR | ARKit + RealityKit | iOS 17+ | Sky flight identification |
| 3D | SceneKit | iOS 17+ | 3D flight view |
| Networking | URLSession + async/await | — | API communication |
| Real-time | WebSocket (URLSessionWebSocketTask) | — | Live position streams |
| Persistence | SwiftData | iOS 17+ | Local database |
| Cloud Sync | CloudKit | — | Cross-device sync |
| Push | APNs | — | Push notifications |
| Live Activities | ActivityKit | iOS 16.2+ | Lock screen / Dynamic Island |
| Widgets | WidgetKit | iOS 17+ | Home/lock screen widgets |
| Watch | WatchKit + SwiftUI | watchOS 10+ | Apple Watch companion |
| Payments | StoreKit 2 | iOS 15+ | Subscriptions |
| Analytics | Firebase Analytics | Latest | Usage tracking |
| Crash Reporting | Firebase Crashlytics | Latest | Crash monitoring |
| Linting | SwiftLint | Latest | Code style enforcement |
| Testing | XCTest + Swift Testing | — | Unit + UI tests |
| CI/CD | Xcode Cloud | — | Build + deploy pipeline |

## Architecture Pattern: MVVM + Clean Architecture

### Why This Pattern

1. **MVVM** naturally maps to SwiftUI's declarative, state-driven UI model
2. **Clean Architecture** layers enforce dependency rules (UI → Domain ← Data)
3. **Protocol-oriented repositories** make testing easy (inject mocks)
4. **@Observable macro** (iOS 17) eliminates Combine boilerplate for ViewModels
5. **Actor isolation** provides thread-safe flight data updates

### Layer Responsibilities

```
┌─────────────────────────────────────────┐
│           PRESENTATION LAYER            │
│                                         │
│  Views (SwiftUI)                        │
│  ├─ Render UI based on ViewModel state  │
│  ├─ Handle user gestures                │
│  └─ No business logic                   │
│                                         │
│  ViewModels (@Observable)               │
│  ├─ Hold UI state                       │
│  ├─ Call Use Cases                       │
│  ├─ Transform domain models → UI models │
│  └─ Handle loading/error states         │
├─────────────────────────────────────────┤
│             DOMAIN LAYER                │
│                                         │
│  Use Cases                              │
│  ├─ Single responsibility operations    │
│  ├─ Orchestrate repository calls        │
│  └─ Contain business rules              │
│                                         │
│  Models                                 │
│  ├─ Pure Swift structs                  │
│  ├─ No framework dependencies           │
│  └─ Represent domain concepts           │
│                                         │
│  Repository Protocols                   │
│  ├─ Define data access contracts        │
│  └─ Owned by domain layer              │
├─────────────────────────────────────────┤
│              DATA LAYER                 │
│                                         │
│  Repository Implementations             │
│  ├─ Implement domain protocols          │
│  ├─ Coordinate API + local DB           │
│  └─ Handle caching strategy             │
│                                         │
│  API Service                            │
│  ├─ HTTP requests via URLSession        │
│  ├─ JSON decoding                       │
│  └─ Error mapping                       │
│                                         │
│  Local Database                         │
│  ├─ SwiftData models                    │
│  ├─ CRUD operations                     │
│  └─ Migration handling                  │
├─────────────────────────────────────────┤
│          INFRASTRUCTURE                 │
│                                         │
│  Network Client, CloudKit, Location,    │
│  Push Notifications, Background Tasks   │
└─────────────────────────────────────────┘
```

### Dependency Rule

Dependencies point **inward only**:
- Presentation → Domain (ViewModels use Use Cases)
- Data → Domain (Repositories implement Domain protocols)
- Domain depends on **nothing** external

```
Presentation ──→ Domain ←── Data
                   ↑
              Infrastructure
```

---

## Key Code Patterns

### 1. ViewModel Pattern (iOS 17 @Observable)

```swift
import SwiftUI

@Observable
final class FlightDetailViewModel {
    // MARK: - State
    var flight: Flight?
    var isLoading = false
    var error: AppError?
    var delayPrediction: DelayPrediction?

    // MARK: - Dependencies
    private let trackFlightUseCase: TrackFlightUseCaseProtocol
    private let predictDelayUseCase: PredictDelayUseCaseProtocol

    init(
        trackFlightUseCase: TrackFlightUseCaseProtocol,
        predictDelayUseCase: PredictDelayUseCaseProtocol
    ) {
        self.trackFlightUseCase = trackFlightUseCase
        self.predictDelayUseCase = predictDelayUseCase
    }

    // MARK: - Actions
    func loadFlight(id: String) async {
        isLoading = true
        error = nil
        do {
            flight = try await trackFlightUseCase.execute(flightId: id)
            delayPrediction = try? await predictDelayUseCase.execute(flightId: id)
        } catch {
            self.error = AppError(from: error)
        }
        isLoading = false
    }

    func refresh() async {
        await loadFlight(id: flight?.id ?? "")
    }
}
```

### 2. Use Case Pattern

```swift
protocol TrackFlightUseCaseProtocol {
    func execute(flightId: String) async throws -> Flight
}

final class TrackFlightUseCase: TrackFlightUseCaseProtocol {
    private let flightRepository: FlightRepositoryProtocol

    init(flightRepository: FlightRepositoryProtocol) {
        self.flightRepository = flightRepository
    }

    func execute(flightId: String) async throws -> Flight {
        let flight = try await flightRepository.getFlight(id: flightId)
        // Business logic: enrich with calculated fields
        return flight
    }
}
```

### 3. Repository Pattern

```swift
protocol FlightRepositoryProtocol {
    func getFlight(id: String) async throws -> Flight
    func searchFlights(query: String) async throws -> [Flight]
    func getFlightPositions(bounds: MapBounds) async throws -> [FlightPosition]
    func getDepartures(airportCode: String) async throws -> [Flight]
    func getArrivals(airportCode: String) async throws -> [Flight]
}

final class FlightRepository: FlightRepositoryProtocol {
    private let apiClient: APIClientProtocol
    private let cache: FlightCacheProtocol
    private let database: FlightDatabaseProtocol

    init(
        apiClient: APIClientProtocol,
        cache: FlightCacheProtocol,
        database: FlightDatabaseProtocol
    ) {
        self.apiClient = apiClient
        self.cache = cache
        self.database = database
    }

    func getFlight(id: String) async throws -> Flight {
        // 1. Check cache
        if let cached = cache.getFlight(id: id), !cached.isStale {
            return cached
        }
        // 2. Fetch from API
        let response = try await apiClient.request(FlightEndpoints.getFlight(id: id))
        let flight = FlightMapper.map(response)
        // 3. Update cache
        cache.store(flight)
        return flight
    }

    // ... other methods
}
```

### 4. API Client Pattern

```swift
protocol APIClientProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
}

final class APIClient: APIClientProtocol {
    private let session: URLSession
    private let baseURL: URL
    private let apiKey: String

    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        var request = URLRequest(url: endpoint.url(base: baseURL))
        request.httpMethod = endpoint.method.rawValue
        request.addValue(apiKey, forHTTPHeaderField: "Authorization")

        Logger.networking.info("→ \(endpoint.method.rawValue) \(endpoint.path)")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        Logger.networking.info("← \(httpResponse.statusCode) \(endpoint.path)")

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
        }

        do {
            return try JSONDecoder.api.decode(T.self, from: data)
        } catch {
            Logger.networking.error("Decode error: \(error)")
            throw APIError.decodingError(error)
        }
    }
}
```

### 5. Dependency Injection

```swift
@Observable
final class DependencyContainer {
    // MARK: - Infrastructure
    lazy var apiClient: APIClientProtocol = APIClient(
        session: .shared,
        baseURL: URL(string: "https://api.aviationstack.com/v1")!,
        apiKey: Configuration.aviationStackAPIKey
    )

    lazy var openSkyClient: OpenSkyClientProtocol = OpenSkyClient(session: .shared)

    // MARK: - Repositories
    lazy var flightRepository: FlightRepositoryProtocol = FlightRepository(
        apiClient: apiClient,
        cache: FlightCache(),
        database: FlightDatabase()
    )

    lazy var airportRepository: AirportRepositoryProtocol = AirportRepository(
        apiClient: apiClient,
        cache: AirportCache()
    )

    // MARK: - Use Cases
    func makeTrackFlightUseCase() -> TrackFlightUseCaseProtocol {
        TrackFlightUseCase(flightRepository: flightRepository)
    }

    func makeSearchFlightsUseCase() -> SearchFlightsUseCaseProtocol {
        SearchFlightsUseCase(flightRepository: flightRepository)
    }

    // MARK: - ViewModels
    func makeFlightDetailViewModel() -> FlightDetailViewModel {
        FlightDetailViewModel(
            trackFlightUseCase: makeTrackFlightUseCase(),
            predictDelayUseCase: makePredictDelayUseCase()
        )
    }

    func makeFlightMapViewModel() -> FlightMapViewModel {
        FlightMapViewModel(
            flightRepository: flightRepository,
            openSkyClient: openSkyClient
        )
    }
}
```

### 6. SwiftUI View Pattern

```swift
struct FlightDetailView: View {
    let flightId: String
    @State private var viewModel: FlightDetailViewModel

    init(flightId: String, container: DependencyContainer) {
        self.flightId = flightId
        self._viewModel = State(initialValue: container.makeFlightDetailViewModel())
    }

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                LoadingView()
            } else if let error = viewModel.error {
                ErrorView(error: error, retryAction: { Task { await viewModel.refresh() } })
            } else if let flight = viewModel.flight {
                FlightHeaderSection(flight: flight)
                FlightProgressSection(flight: flight)
                FlightTimesSection(flight: flight)
                FlightGateSection(flight: flight)
                AircraftInfoCard(aircraft: flight.aircraft)
                if let prediction = viewModel.delayPrediction {
                    DelayPredictionCard(prediction: prediction)
                }
            }
        }
        .refreshable { await viewModel.refresh() }
        .task { await viewModel.loadFlight(id: flightId) }
    }
}
```

---

## Data Flow: Real-Time Flight Tracking

```
OpenSky API (HTTP poll every 10s)
         │
         ▼
  ┌──────────────┐
  │  APIClient    │  Fetch positions for visible map bounds
  └──────┬───────┘
         │
         ▼
  ┌──────────────┐
  │  Repository   │  Map API response → domain FlightPosition models
  └──────┬───────┘
         │
         ▼
  ┌──────────────┐
  │  ViewModel    │  Update @Observable positions array
  │  (@Observable)│  Animate transitions between old → new positions
  └──────┬───────┘
         │
         ▼ (SwiftUI automatic re-render)
  ┌──────────────┐
  │    MapView    │  MapAnnotations re-render with new coordinates
  │  (SwiftUI)   │  Aircraft icons rotate to new headings
  └──────────────┘
```

---

## Error Handling Strategy

```swift
enum AppError: LocalizedError {
    case network(NetworkError)
    case api(APIError)
    case persistence(PersistenceError)
    case location(LocationError)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .network(.noConnection):
            return "No internet connection. Showing cached data."
        case .network(.timeout):
            return "Request timed out. Please try again."
        case .api(.rateLimited):
            return "Too many requests. Please wait a moment."
        case .api(.notFound):
            return "Flight not found. Check the flight number."
        case .persistence(.migrationFailed):
            return "Database error. Please restart the app."
        default:
            return "Something went wrong. Please try again."
        }
    }
}
```

---

## Testing Strategy

### Unit Tests (Target: ≥ 80% coverage on Domain + Data layers)

| Test Target | What to Test | Mocking |
|-------------|-------------|---------|
| ViewModels | State changes, loading/error handling | Mock Use Cases |
| Use Cases | Business logic, data transformation | Mock Repositories |
| Repositories | Cache hit/miss, API ↔ DB coordination | Mock APIClient, Database |
| API Models | JSON parsing, edge cases | JSON fixture files |
| Services | Delay prediction, notification logic | Mock dependencies |
| Utilities | Date formatting, coordinate math | None (pure functions) |

### UI Tests

| Flow | Steps |
|------|-------|
| Search & Track | Launch → Search tab → Type "UA123" → Tap result → Verify detail |
| Add My Flight | My Flights tab → Add button → Enter flight → Verify in list |
| Map Interaction | Map tab → Pinch zoom → Tap aircraft → Verify sheet opens |
| Airport Browse | Search → Type "SFO" → Tap airport → Verify boards load |

### JSON Fixtures Location

```
SkyTrackTests/
  Fixtures/
    flight_response.json
    flight_response_delayed.json
    flight_response_cancelled.json
    airport_response.json
    positions_response.json
    weather_response.json
    empty_response.json
    error_response.json
```

---

## Performance Budgets

| Metric | Budget | Measurement |
|--------|--------|-------------|
| Cold launch | < 1.5s | Instruments: App Launch |
| Map initial render | < 2s | Instruments: Time Profiler |
| Flight search → results | < 1s (cached) / < 2s (network) | Custom timing |
| Memory (browsing map) | < 100MB | Instruments: Allocations |
| Memory (AR view) | < 200MB | Instruments: Allocations |
| Battery (background, 8hr) | < 5% | Instruments: Energy Log |
| App size | < 50MB | Xcode Archive |
| Widget refresh | Every 15 min ± 5 min | WidgetKit timeline logs |

---

## Security Considerations

| Area | Approach |
|------|----------|
| API keys | Stored in `.xcconfig` files, NOT in source control. Use `Secrets.xcconfig` in `.gitignore` |
| Network | All API calls over HTTPS (TLS 1.3) |
| User data | Flights stored in app sandbox (SwiftData). Synced via CloudKit (encrypted) |
| Keychain | Subscription receipt + API tokens stored in Keychain |
| Logging | No PII in os_log. Flight numbers OK, user emails NEVER logged |
| App Transport Security | Enforce ATS (no HTTP exceptions except for test environments) |
