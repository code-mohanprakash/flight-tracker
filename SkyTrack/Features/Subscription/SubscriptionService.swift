import Foundation
import StoreKit
import os

/// Tip Jar service — SkyTrack is completely free. Users can optionally tip
/// to support development. All features are always unlocked for everyone.
@Observable
final class TipJarService {
    var products: [Product] = []
    var purchasedTipIDs: Set<String> = []
    var isLoading = false
    var hasTipped = false

    private var updateListenerTask: Task<Void, Never>?
    private static let logger = Logger(subsystem: "com.skytrack.app", category: "tip-jar")

    // MARK: - Product IDs

    enum ProductID {
        static let smallTip = "com.skytrack.tip.small"     // $0.99
        static let mediumTip = "com.skytrack.tip.medium"   // $4.99
        static let largeTip = "com.skytrack.tip.large"     // $9.99
        static let hugeTip = "com.skytrack.tip.huge"       // $24.99

        static let all: [String] = [smallTip, mediumTip, largeTip, hugeTip]
    }

    // MARK: - App Features (all free)

    enum AppFeature: String, CaseIterable {
        case delayPredictions = "Delay Predictions"
        case liveActivities = "Live Activities"
        case arView = "AR Sky View"
        case flight3D = "3D Flight View"
        case advancedFilters = "Advanced Map Filters"
        case weatherLayers = "Weather Layers"
        case yearInReview = "Year in Review"
        case unlimitedFlights = "Unlimited Flights"
        case friendsTracking = "Friends Tracking"
        case widgets = "All Widgets"

        var iconName: String {
            switch self {
            case .delayPredictions: "chart.line.uptrend.xyaxis"
            case .liveActivities: "livephoto"
            case .arView: "camera.viewfinder"
            case .flight3D: "cube"
            case .advancedFilters: "slider.horizontal.3"
            case .weatherLayers: "cloud.sun"
            case .yearInReview: "sparkles"
            case .unlimitedFlights: "infinity"
            case .friendsTracking: "person.2"
            case .widgets: "rectangle.3.group"
            }
        }

        var description: String {
            switch self {
            case .delayPredictions: "AI-powered delay predictions hours before airlines announce"
            case .liveActivities: "Real-time Dynamic Island and lock screen updates"
            case .arView: "Point your camera at the sky to identify flights"
            case .flight3D: "Immersive 3D flight visualization with cockpit view"
            case .advancedFilters: "Filter by altitude, speed, airline, and more"
            case .weatherLayers: "Live weather overlay on the flight map"
            case .yearInReview: "Beautiful animated travel year summary"
            case .unlimitedFlights: "Track unlimited flights simultaneously"
            case .friendsTracking: "Share and track flights with friends"
            case .widgets: "Home screen, lock screen, and watch widgets"
            }
        }
    }

    // MARK: - Lifecycle

    init() {
        updateListenerTask = listenForTransactions()
        loadTipHistory()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    /// All features are always available — this is a free app
    func isFeatureAvailable(_ feature: AppFeature) -> Bool {
        true
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: ProductID.all)
                .sorted { $0.price < $1.price }
            Self.logger.info("Loaded \(self.products.count) tip products")
        } catch {
            Self.logger.error("Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase (Tip)

    func tip(_ product: Product) async throws -> StoreKit.Transaction? {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            purchasedTipIDs.insert(product.id)
            hasTipped = true
            saveTipHistory()
            await transaction.finish()
            Self.logger.info("Tip received: \(product.id)")
            return transaction

        case .userCancelled:
            Self.logger.info("User cancelled tip")
            return nil

        case .pending:
            Self.logger.info("Tip pending")
            return nil

        @unknown default:
            return nil
        }
    }

    // MARK: - Private

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if let transaction = try? self?.checkVerified(result) {
                    self?.hasTipped = true
                    await transaction.finish()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }

    private func saveTipHistory() {
        UserDefaults.standard.set(true, forKey: "skytrack_has_tipped")
    }

    private func loadTipHistory() {
        hasTipped = UserDefaults.standard.bool(forKey: "skytrack_has_tipped")
    }
}
