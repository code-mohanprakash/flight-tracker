import SwiftUI

struct NotificationSettingsView: View {
    @AppStorage("notif_departures") private var departures = true
    @AppStorage("notif_arrivals") private var arrivals = true
    @AppStorage("notif_gate_changes") private var gateChanges = true
    @AppStorage("notif_delays") private var delays = true
    @AppStorage("notif_cancellations") private var cancellations = true
    @AppStorage("notif_boarding") private var boarding = true
    @AppStorage("notif_baggage") private var baggage = true
    @AppStorage("notif_predictions") private var predictions = true

    @State private var permissionStatus: String = "Checking..."
    @State private var showPermissionAlert = false

    var body: some View {
        List {
            // Permission Status
            Section {
                HStack {
                    Image(systemName: "bell.badge")
                        .foregroundStyle(AppColors.primary)
                    Text("Notification Permission")
                    Spacer()
                    Text(permissionStatus)
                        .font(AppTypography.caption)
                        .foregroundStyle(permissionStatus == "Enabled" ? AppColors.onTime : AppColors.cancelled)
                }
            } footer: {
                if permissionStatus != "Enabled" {
                    Text("Enable notifications in Settings to receive flight alerts.")
                }
            }

            // Critical Alerts
            Section("Critical Alerts") {
                Toggle(isOn: $cancellations) {
                    notificationRow(
                        icon: "xmark.circle.fill",
                        iconColor: .red,
                        title: "Cancellations",
                        description: "Alert when your flight is cancelled"
                    )
                }
                .tint(AppColors.primary)

                Toggle(isOn: $gateChanges) {
                    notificationRow(
                        icon: "door.left.hand.open",
                        iconColor: .blue,
                        title: "Gate Changes",
                        description: "Alert when your departure gate changes"
                    )
                }
                .tint(AppColors.primary)
            }

            // Delay & Prediction Alerts
            Section("Delay Alerts") {
                Toggle(isOn: $delays) {
                    notificationRow(
                        icon: "clock.fill",
                        iconColor: .orange,
                        title: "Delay Updates",
                        description: "Alert when departure or arrival time changes > 10 min"
                    )
                }
                .tint(AppColors.primary)

                Toggle(isOn: $predictions) {
                    notificationRow(
                        icon: "chart.line.uptrend.xyaxis",
                        iconColor: .purple,
                        title: "Delay Predictions",
                        description: "AI-powered delay predictions before airline announces"
                    )
                }
                .tint(AppColors.primary)
            }

            // Status Updates
            Section("Status Updates") {
                Toggle(isOn: $departures) {
                    notificationRow(
                        icon: "airplane.departure",
                        iconColor: .blue,
                        title: "Departures",
                        description: "Alert when your flight departs"
                    )
                }
                .tint(AppColors.primary)

                Toggle(isOn: $arrivals) {
                    notificationRow(
                        icon: "airplane.arrival",
                        iconColor: .green,
                        title: "Arrivals",
                        description: "Alert when your flight lands"
                    )
                }
                .tint(AppColors.primary)

                Toggle(isOn: $boarding) {
                    notificationRow(
                        icon: "figure.walk",
                        iconColor: .blue,
                        title: "Boarding Reminder",
                        description: "Reminder 30 minutes before departure"
                    )
                }
                .tint(AppColors.primary)

                Toggle(isOn: $baggage) {
                    notificationRow(
                        icon: "suitcase.fill",
                        iconColor: .brown,
                        title: "Baggage Claim",
                        description: "Alert when baggage carousel is assigned"
                    )
                }
                .tint(AppColors.primary)
            }
        }
        .navigationTitle("Notifications")
        .task { await checkPermission() }
    }

    // MARK: - Helpers

    private func notificationRow(icon: String, iconColor: Color, title: String, description: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(iconColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(title)
                    .font(AppTypography.body)
                Text(description)
                    .font(AppTypography.small)
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
    }

    private func checkPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            switch settings.authorizationStatus {
            case .authorized: permissionStatus = "Enabled"
            case .denied: permissionStatus = "Disabled"
            case .provisional: permissionStatus = "Provisional"
            case .notDetermined: permissionStatus = "Not Set"
            @unknown default: permissionStatus = "Unknown"
            }
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
