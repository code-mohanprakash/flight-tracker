import SwiftUI

struct StatusBadge: View {
    let status: FlightStatus

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: status.iconName)
                .font(.system(size: 10, weight: .bold))
            Text(status.displayName)
                .font(AppTypography.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(status.color.opacity(0.15))
        .foregroundStyle(status.color)
        .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 8) {
        StatusBadge(status: .scheduled)
        StatusBadge(status: .active)
        StatusBadge(status: .landed)
        StatusBadge(status: .cancelled)
        StatusBadge(status: .diverted)
    }
    .padding()
    .background(AppColors.background)
}
