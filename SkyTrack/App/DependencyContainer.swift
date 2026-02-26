import SwiftUI

@Observable
final class DependencyContainer {
    // MARK: - Infrastructure

    lazy var apiClient: APIClientProtocol = APIClient(
        session: .shared,
        configuration: .init(
            baseURL: URL(string: "https://api.aviationstack.com/v1")!,
            apiKey: Configuration.aviationStackAPIKey
        )
    )

    lazy var openSkyClient: OpenSkyClientProtocol = OpenSkyClient(session: .shared)
    lazy var flightCache: FlightCache = FlightCache()
    lazy var airportCache: AirportCache = AirportCache()

    // MARK: - Repositories

    lazy var flightRepository: FlightRepositoryProtocol = FlightRepository(
        apiClient: apiClient,
        openSkyClient: openSkyClient,
        cache: flightCache
    )

    lazy var airportRepository: AirportRepositoryProtocol = AirportRepository(
        apiClient: apiClient,
        cache: airportCache
    )

    lazy var userFlightRepository: UserFlightRepositoryProtocol = UserFlightRepository()

    // MARK: - Services (Phase 2)

    lazy var notificationService: NotificationService = NotificationService()

    lazy var delayPredictionService: DelayPredictionService = DelayPredictionService(
        flightRepository: flightRepository,
        airportRepository: airportRepository
    )

    lazy var flightTrackingService: FlightTrackingService = FlightTrackingService(
        flightRepository: flightRepository,
        delayPredictionService: delayPredictionService,
        notificationService: notificationService
    )

    lazy var importService: ImportService = ImportService()

    #if canImport(ActivityKit)
    lazy var liveActivityManager: LiveActivityManager = LiveActivityManager()
    #endif

    // MARK: - Services (Phase 3)

    lazy var sharingService: SharingService = SharingService()

    lazy var friendsTrackingService: FriendsTrackingService = FriendsTrackingService()

    lazy var travelStatsService: TravelStatsService = TravelStatsService(
        userFlightRepository: userFlightRepository,
        flightRepository: flightRepository
    )

    // MARK: - Use Cases

    func makeTrackFlightUseCase() -> TrackFlightUseCase {
        TrackFlightUseCase(flightRepository: flightRepository)
    }

    func makeSearchFlightsUseCase() -> SearchFlightsUseCase {
        SearchFlightsUseCase(flightRepository: flightRepository, airportRepository: airportRepository)
    }

    func makeGetAirportInfoUseCase() -> GetAirportInfoUseCase {
        GetAirportInfoUseCase(airportRepository: airportRepository)
    }

    // MARK: - ViewModels

    func makeFlightMapViewModel() -> FlightMapViewModel {
        FlightMapViewModel(flightRepository: flightRepository)
    }

    func makeFlightDetailViewModel(flightId: String) -> FlightDetailViewModel {
        FlightDetailViewModel(
            flightId: flightId,
            trackFlightUseCase: makeTrackFlightUseCase()
        )
    }

    func makeSearchViewModel() -> SearchViewModel {
        SearchViewModel(searchUseCase: makeSearchFlightsUseCase())
    }

    func makeMyFlightsViewModel() -> MyFlightsViewModel {
        MyFlightsViewModel(
            userFlightRepository: userFlightRepository,
            flightRepository: flightRepository
        )
    }

    func makeAirportViewModel(airportCode: String) -> AirportViewModel {
        AirportViewModel(
            airportCode: airportCode,
            airportUseCase: makeGetAirportInfoUseCase(),
            flightRepository: flightRepository
        )
    }

    func makeARSkyViewModel() -> ARSkyViewModel {
        ARSkyViewModel(flightRepository: flightRepository)
    }

    func makeFlight3DViewModel() -> Flight3DViewModel {
        Flight3DViewModel()
    }
}
