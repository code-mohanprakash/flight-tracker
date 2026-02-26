import SwiftUI

struct SettingsView: View {
    @AppStorage("notifications_enabled") private var notificationsEnabled = true
    @AppStorage("distance_unit") private var distanceUnit = "km"
    @AppStorage("temperature_unit") private var temperatureUnit = "celsius"
    @AppStorage("map_style") private var mapStyle = "standard"
    @State private var showTipJar = false

    var body: some View {
        NavigationStack {
            List {
                // Support
                Section {
                    Button {
                        showTipJar = true
                    } label: {
                        HStack {
                            Label("Tip Jar", systemImage: "heart.fill")
                                .foregroundStyle(Color(hex: "FF6B6B"))
                            Spacer()
                            Text("Support the dev")
                                .font(.caption)
                                .foregroundStyle(AppColors.textTertiary)
                            Image(systemName: AppIcons.chevronRight)
                                .font(.caption)
                                .foregroundStyle(AppColors.textTertiary)
                        }
                    }
                } footer: {
                    Text("SkyTrack is 100% free. All features included, no ads, no subscriptions.")
                }

                // Notifications
                Section {
                    Toggle(isOn: $notificationsEnabled) {
                        Label("Push Notifications", systemImage: AppIcons.notification)
                    }
                    .tint(AppColors.primary)

                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("Notification Preferences", systemImage: "bell.badge")
                    }
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
            .sheet(isPresented: $showTipJar) {
                TipJarView(tipJarService: TipJarService())
            }
        }
    }
}

#Preview {
    SettingsView()
}
