import XCTest
@testable import SkyTrack

final class SearchViewModelTests: XCTestCase {

    func testInitialState() {
        let vm = createViewModel()

        XCTAssertEqual(vm.query, "")
        XCTAssertTrue(vm.results.isEmpty)
        XCTAssertFalse(vm.isSearching)
        XCTAssertNil(vm.error)
    }

    func testClearSearch_resetsState() {
        let vm = createViewModel()
        vm.query = "UA123"
        vm.clearSearch()

        XCTAssertEqual(vm.query, "")
        XCTAssertTrue(vm.results.isEmpty)
    }

    func testRemoveRecentSearch() {
        let vm = createViewModel()
        // Manually add a recent search for testing
        UserDefaults.standard.set(["UA123", "SFO", "DL456"], forKey: "com.skytrack.recentSearches")
        vm.removeRecentSearch("SFO")

        let remaining = UserDefaults.standard.stringArray(forKey: "com.skytrack.recentSearches") ?? []
        XCTAssertFalse(remaining.contains("SFO"))
    }

    func testSearchType_allCases() {
        let allCases = SearchViewModel.SearchType.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.all))
        XCTAssertTrue(allCases.contains(.flights))
        XCTAssertTrue(allCases.contains(.airports))
    }

    // MARK: - Helpers

    private func createViewModel() -> SearchViewModel {
        let mockFlightRepo = MockFlightRepository()
        let mockAirportRepo = MockAirportRepository()
        let useCase = SearchFlightsUseCase(
            flightRepository: mockFlightRepo,
            airportRepository: mockAirportRepo
        )
        return SearchViewModel(searchUseCase: useCase)
    }
}

// MARK: - Mock Airport Repository

final class MockAirportRepository: AirportRepositoryProtocol, @unchecked Sendable {
    var airportToReturn: Airport?
    var airportsToReturn: [Airport] = []
    var errorToThrow: AppError?

    func getAirport(code: String) async throws -> Airport? {
        if let error = errorToThrow { throw error }
        return airportToReturn
    }

    func searchAirports(query: String) async throws -> [Airport] {
        if let error = errorToThrow { throw error }
        return airportsToReturn
    }
}
