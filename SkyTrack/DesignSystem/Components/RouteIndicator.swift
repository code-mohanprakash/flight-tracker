import SwiftUI

struct RouteIndicator: View {
    let progress: Double? // nil = no progress (scheduled), 0-1 = in flight
    var compact: Bool = false

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            ZStack(alignment: .leading) {
                // Track line
                Capsule()
                    .fill(AppColors.textTertiary.opacity(0.3))
                    .frame(height: 2)

                // Progress fill
                if let progress {
                    Capsule()
                        .fill(AppColors.primary)
                        .frame(width: width * min(max(progress, 0), 1), height: 2)
                }

                // Origin dot
                Circle()
                    .fill(AppColors.textSecondary)
                    .frame(width: compact ? 6 : 8, height: compact ? 6 : 8)

                // Destination dot
                Circle()
                    .fill(progress == 1.0 ? AppColors.onTime : AppColors.textSecondary)
                    .frame(width: compact ? 6 : 8, height: compact ? 6 : 8)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                // Airplane icon
                if let progress, progress > 0 && progress < 1 {
                    Image(systemName: "airplane")
                        .font(.system(size: compact ? 12 : 16, weight: .bold))
                        .foregroundStyle(AppColors.primary)
                        .offset(x: width * progress - (compact ? 6 : 8))
                }
            }
        }
        .frame(height: compact ? 16 : 20)
    }
}

#Preview {
    VStack(spacing: 20) {
        RouteIndicator(progress: nil)
        RouteIndicator(progress: 0.0)
        RouteIndicator(progress: 0.35)
        RouteIndicator(progress: 0.7)
        RouteIndicator(progress: 1.0)
        RouteIndicator(progress: 0.5, compact: true)
    }
    .padding(24)
    .background(AppColors.background)
}
