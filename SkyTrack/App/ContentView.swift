import SwiftUI

struct ContentView: View {
    @Environment(DependencyContainer.self) private var container
    @State private var selectedTab: AppTab = .map

    var body: some View {
        TabView(selection: $selectedTab) {
            FlightMapView(viewModel: container.makeFlightMapViewModel())
                .tabItem {
                    Label("Map", systemImage: "globe")
                }
                .tag(AppTab.map)

            MyFlightsView(viewModel: container.makeMyFlightsViewModel())
                .tabItem {
                    Label("My Flights", systemImage: "airplane")
                }
                .tag(AppTab.myFlights)

            SearchView(viewModel: container.makeSearchViewModel())
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(AppTab.search)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(AppTab.settings)
        }
        .tint(AppColors.primary)
    }
}

enum AppTab: Hashable {
    case map
    case myFlights
    case search
    case settings
}

#Preview {
    ContentView()
        .environment(DependencyContainer())
}
