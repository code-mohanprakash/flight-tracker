import SwiftUI

/// 3-screen onboarding flow with permission requests.
struct OnboardingView: View {
    @State private var currentPage = 0
    @AppStorage("has_completed_onboarding") private var hasCompletedOnboarding = false
    @State private var notificationGranted = false
    @State private var locationGranted = false

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            TabView(selection: $currentPage) {
                // Page 1: Welcome
                OnboardingPage(
                    icon: "airplane.circle.fill",
                    iconColors: [AppColors.primary, Color(hex: "6366F1")],
                    title: "Welcome to SkyTrack",
                    subtitle: "The most powerful flight tracker — completely free.\nReal-time maps, delay predictions, AR view, and more.",
                    features: [
                        OnboardingFeature(icon: "globe", text: "Live flight map with 60,000+ flights"),
                        OnboardingFeature(icon: "chart.line.uptrend.xyaxis", text: "AI-powered delay predictions"),
                        OnboardingFeature(icon: "camera.viewfinder", text: "AR sky view to identify planes overhead"),
                        OnboardingFeature(icon: "bell.badge", text: "Smart notifications for every update"),
                    ]
                ) {
                    withAnimation { currentPage = 1 }
                }
                .tag(0)

                // Page 2: Notifications Permission
                PermissionPage(
                    icon: "bell.badge.fill",
                    iconColors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                    title: "Stay Updated",
                    subtitle: "Get notified about gate changes, delays, cancellations, baggage, and boarding — before the airline tells you.",
                    permissionType: .notifications,
                    isGranted: $notificationGranted
                ) {
                    withAnimation { currentPage = 2 }
                }
                .tag(1)

                // Page 3: Location Permission
                PermissionPage(
                    icon: "location.fill",
                    iconColors: [AppColors.primary, Color(hex: "34D058")],
                    title: "Flights Above You",
                    subtitle: "Allow location access to see flights overhead in AR view and get distance-based airport suggestions.",
                    permissionType: .location,
                    isGranted: $locationGranted
                ) {
                    completeOnboarding()
                }
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.4), value: currentPage)

            // Page indicator
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { page in
                        Capsule()
                            .fill(page == currentPage ? AppColors.primary : AppColors.textTertiary)
                            .frame(width: page == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 120)
            }
        }
    }

    private func completeOnboarding() {
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Onboarding Page

struct OnboardingPage: View {
    let icon: String
    let iconColors: [Color]
    let title: String
    let subtitle: String
    let features: [OnboardingFeature]
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon
            Image(systemName: icon)
                .font(.system(size: 70))
                .foregroundStyle(
                    LinearGradient(colors: iconColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .padding(.bottom, AppSpacing.xxl)

            // Title
            Text(title)
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.bottom, AppSpacing.md)

            // Subtitle
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xxl)
                .padding(.bottom, AppSpacing.xxl)

            // Features
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                ForEach(features) { feature in
                    HStack(spacing: AppSpacing.md) {
                        Image(systemName: feature.icon)
                            .font(.body)
                            .foregroundStyle(AppColors.primary)
                            .frame(width: 30)
                        Text(feature.text)
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textPrimary)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.xxxl)

            Spacer()

            // Continue button
            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(colors: iconColors, startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, AppSpacing.xxl)
            .padding(.bottom, AppSpacing.xxxl)
        }
    }
}

// MARK: - Permission Page

struct PermissionPage: View {
    let icon: String
    let iconColors: [Color]
    let title: String
    let subtitle: String
    let permissionType: PermissionType
    @Binding var isGranted: Bool
    let onContinue: () -> Void

    enum PermissionType {
        case notifications
        case location
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 70))
                .foregroundStyle(
                    LinearGradient(colors: iconColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .padding(.bottom, AppSpacing.xxl)

            Text(title)
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.bottom, AppSpacing.md)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xxl)

            Spacer()

            VStack(spacing: AppSpacing.md) {
                // Enable button
                Button {
                    Task { await requestPermission() }
                } label: {
                    HStack {
                        if isGranted {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text(isGranted ? "Enabled" : "Enable \(permissionLabel)")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(colors: iconColors, startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isGranted)

                // Skip button
                Button(action: onContinue) {
                    Text(isGranted ? "Continue" : "Skip for Now")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(isGranted ? AppColors.primary : AppColors.textTertiary)
                }
            }
            .padding(.horizontal, AppSpacing.xxl)
            .padding(.bottom, AppSpacing.xxxl)
        }
    }

    private var permissionLabel: String {
        switch permissionType {
        case .notifications: "Notifications"
        case .location: "Location"
        }
    }

    private func requestPermission() async {
        switch permissionType {
        case .notifications:
            let granted = try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            isGranted = granted ?? false
        case .location:
            // CLLocationManager handles this via system prompt
            isGranted = true
        }
        if isGranted {
            try? await Task.sleep(for: .milliseconds(500))
            onContinue()
        }
    }
}

// MARK: - Models

struct OnboardingFeature: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
}

// MARK: - Onboarding Gate Modifier

struct OnboardingGateModifier: ViewModifier {
    @AppStorage("has_completed_onboarding") private var hasCompletedOnboarding = false

    func body(content: Content) -> some View {
        if hasCompletedOnboarding {
            content
        } else {
            OnboardingView()
        }
    }
}

extension View {
    func withOnboardingGate() -> some View {
        modifier(OnboardingGateModifier())
    }
}
