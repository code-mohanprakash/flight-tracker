import SwiftUI

struct ErrorView: View {
    let error: AppError
    var retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: error.iconName)
                .font(.system(size: 48))
                .foregroundStyle(AppColors.textTertiary)

            VStack(spacing: AppSpacing.sm) {
                Text(error.title)
                    .font(AppTypography.subheading)
                    .foregroundStyle(AppColors.textPrimary)

                Text(error.message)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let retryAction {
                Button(action: retryAction) {
                    Label("Try Again", systemImage: AppIcons.refresh)
                        .font(AppTypography.body)
                        .fontWeight(.medium)
                        .padding(.horizontal, AppSpacing.xl)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.primary)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(AppSpacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}

#Preview {
    ErrorView(
        error: .network(.noConnection),
        retryAction: {}
    )
}
