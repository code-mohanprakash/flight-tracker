import SwiftUI

struct LoadingView: View {
    var message: String = "Loading..."

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            ProgressView()
                .controlSize(.large)
                .tint(AppColors.primary)
            Text(message)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            AppColors.overlay
                .ignoresSafeArea()
            ProgressView()
                .controlSize(.large)
                .tint(AppColors.primary)
                .padding(AppSpacing.xxl)
                .background(AppColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
        }
    }
}

#Preview {
    LoadingView()
}
