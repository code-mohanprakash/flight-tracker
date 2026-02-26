import SwiftUI

struct CardModifier: ViewModifier {
    var padding: CGFloat = AppSpacing.cardPadding

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
    }
}

struct ElevatedCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppSpacing.cardPadding)
            .background(AppColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func card(padding: CGFloat = AppSpacing.cardPadding) -> some View {
        modifier(CardModifier(padding: padding))
    }

    func elevatedCard() -> some View {
        modifier(ElevatedCardModifier())
    }
}
