import SwiftUI

struct SettingsView: View {
    @AppStorage("notifications_enabled") private var notificationsEnabled = true
    @AppStorage("distance_unit") private var distanceUnit = "km"
    @AppStorage("temperature_unit") private var temperatureUnit = "celsius"
    @AppStorage("map_style") private var mapStyle = "standard"

    var body: some View {
        NavigationStack {
            List {
                // Notifications
                Section {
                    Toggle(isOn: $notificationsEnabled) {
                        Label("Push Notifications", systemImage: AppIcons.notification)
                    }
                    .tint(AppColors.primary)
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Receive alerts for gate changes, delays, cancellations, and more.")
                }

                // Units
                Section("Units") {
                    Picker("Distance", selection: $distanceUnit) {
                        Text("Kilometers").tag("km")
                        Text("Miles").tag("mi")
                        Text("Nautical Miles").tag("nm")
                    }
                    Picker("Temperature", selection: $temperatureUnit) {
                        Text("Celsius").tag("celsius")
                        Text("Fahrenheit").tag("fahrenheit")
                    }
                }

                // Map
                Section("Map") {
                    Picker("Map Style", selection: $mapStyle) {
                        Text("Standard").tag("standard")
                        Text("Satellite").tag("satellite")
                        Text("Hybrid").tag("hybrid")
                    }
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }

                // Data
                Section {
                    Link(destination: URL(string: "https://opensky-network.org")!) {
                        HStack {
                            Text("Flight Data: OpenSky Network")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12))
                        }
                    }
                    Link(destination: URL(string: "https://aviationstack.com")!) {
                        HStack {
                            Text("API: AviationStack")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12))
                        }
                    }
                } header: {
                    Text("Data Sources")
                }

                // Legal
                Section("Legal") {
                    NavigationLink("Privacy Policy") {
                        Text("Privacy Policy content here")
                            .navigationTitle("Privacy Policy")
                    }
                    NavigationLink("Terms of Service") {
                        Text("Terms of Service content here")
                            .navigationTitle("Terms of Service")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
