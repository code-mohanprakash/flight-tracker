import Foundation
import Combine
import os

@Observable
final class SearchViewModel {
    // MARK: - State
    var query: String = "" {
        didSet { debounceSearch() }
    }
    var results: [SearchResult] = []
    var recentSearches: [String] = []
    var isSearching = false
    var error: AppError?
    var selectedSearchType: SearchType = .all

    enum SearchType: String, CaseIterable {
        case all = "All"
        case flights = "Flights"
        case airports = "Airports"
    }

    // MARK: - Private
    private let searchUseCase: SearchFlightsUseCase
    private var searchTask: Task<Void, Never>?
    private static let logger = Logger(subsystem: "com.skytrack.app", category: "search")
    private let recentSearchesKey = "com.skytrack.recentSearches"

    init(searchUseCase: SearchFlightsUseCase) {
        self.searchUseCase = searchUseCase
        loadRecentSearches()
    }

    // MARK: - Actions

    func performSearch() {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            results = []
            return
        }

        searchTask?.cancel()
        searchTask = Task { [weak self] in
            guard let self else { return }

            await MainActor.run { self.isSearching = true; self.error = nil }

            do {
                let searchResults: [SearchResult]
                switch self.selectedSearchType {
                case .all:
                    searchResults = try await self.searchUseCase.search(query: trimmedQuery)
                case .flights:
                    let flights = try await self.searchUseCase.searchFlights(query: trimmedQuery)
                    searchResults = flights.map { .flight($0) }
                case .airports:
                    let airports = try await self.searchUseCase.searchAirports(query: trimmedQuery)
                    searchResults = airports.map { .airport($0) }
                }

                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.results = searchResults
                    self.isSearching = false
                }

                Self.logger.info("Search '\(trimmedQuery)' returned \(searchResults.count) results")
                self.saveRecentSearch(trimmedQuery)
            } catch {
                guard !Task.isCancelled else { return }
                Self.logger.error("Search failed: \(error)")
                await MainActor.run {
                    self.isSearching = false
                    self.error = error as? AppError ?? .unknown(error.localizedDescription)
                }
            }
        }
    }

    func clearSearch() {
        query = ""
        results = []
        searchTask?.cancel()
    }

    func removeRecentSearch(_ search: String) {
        recentSearches.removeAll { $0 == search }
        UserDefaults.standard.set(recentSearches, forKey: recentSearchesKey)
    }

    // MARK: - Private

    private func debounceSearch() {
        searchTask?.cancel()
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            results = []
            return
        }
        searchTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Configuration.searchDebounceInterval))
            guard !Task.isCancelled else { return }
            self?.performSearch()
        }
    }

    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: recentSearchesKey) ?? []
    }

    private func saveRecentSearch(_ search: String) {
        var searches = recentSearches
        searches.removeAll { $0.caseInsensitiveCompare(search) == .orderedSame }
        searches.insert(search, at: 0)
        if searches.count > 10 { searches = Array(searches.prefix(10)) }
        recentSearches = searches
        UserDefaults.standard.set(searches, forKey: recentSearchesKey)
    }
}
