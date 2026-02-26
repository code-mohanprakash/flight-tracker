import SwiftUI
import StoreKit

/// Tip Jar — SkyTrack is 100% free. This view lets users optionally
/// support the developer with a one-time tip. No features are gated.
struct TipJarView: View {
    @State var tipJarService: TipJarService
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showThankYou = false
    @State private var purchaseError: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.xxl) {
                    heroSection
                    freeFeaturesBanner
                    tipOptions
                    tipButton
                    footer
                }
                .padding(.bottom, AppSpacing.xxxl)
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: AppIcons.close)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
            .task {
                await tipJarService.loadProducts()
            }
            .alert("Thank You!", isPresented: $showThankYou) {
                Button("You're Welcome") { dismiss() }
            } message: {
                Text("Your support means the world and helps keep SkyTrack free for everyone!")
            }
            .alert("Error", isPresented: .init(
                get: { purchaseError != nil },
                set: { if !$0 { purchaseError = nil } }
            )) {
                Button("OK") { purchaseError = nil }
            } message: {
                Text(purchaseError ?? "")
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "heart.fill")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.top, AppSpacing.xl)

            Text("Support SkyTrack")
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(AppColors.textPrimary)

            Text("SkyTrack is and always will be completely free.\nIf you enjoy it, consider leaving a tip!")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if tipJarService.hasTipped {
                Label("Thank you for your support!", systemImage: "heart.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.onTime)
            }
        }
    }

    // MARK: - Free Banner

    private var freeFeaturesBanner: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(AppColors.onTime)
                Text("All features included — free forever")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
            }

            // Feature list
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 6) {
                ForEach(TipJarService.AppFeature.allCases, id: \.rawValue) { feature in
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(AppColors.onTime)
                        Text(feature.rawValue)
                            .font(.system(size: 10))
                            .foregroundStyle(AppColors.textSecondary)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Tip Options

    private var tipOptions: some View {
        VStack(spacing: AppSpacing.md) {
            Text("Leave a Tip")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)

            HStack(spacing: AppSpacing.md) {
                ForEach(tipJarService.products, id: \.id) { product in
                    TipCard(
                        product: product,
                        emoji: emojiForProduct(product),
                        isSelected: selectedProduct?.id == product.id
                    ) {
                        withAnimation(.spring(duration: 0.3)) {
                            selectedProduct = product
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Tip Button

    private var tipButton: some View {
        Button {
            Task { await performTip() }
        } label: {
            Group {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    HStack {
                        Image(systemName: "heart.fill")
                        Text(selectedProduct != nil ? "Tip \(selectedProduct!.displayPrice)" : "Select a Tip Amount")
                    }
                    .font(.headline)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(selectedProduct == nil || isPurchasing)
        .padding(.horizontal)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: AppSpacing.sm) {
            Text("Tips are one-time purchases. No subscriptions, no recurring charges.")
                .font(.caption)
                .foregroundStyle(AppColors.textTertiary)
                .multilineTextAlignment(.center)

            HStack(spacing: AppSpacing.lg) {
                Button("Privacy Policy") {}
                    .font(.caption2)
                    .foregroundStyle(AppColors.textTertiary)
                Button("Terms of Service") {}
                    .font(.caption2)
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
        .padding(.horizontal, AppSpacing.xl)
    }

    // MARK: - Actions

    private func performTip() async {
        guard let product = selectedProduct else { return }
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            if let _ = try await tipJarService.tip(product) {
                showThankYou = true
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    private func emojiForProduct(_ product: Product) -> String {
        switch product.id {
        case TipJarService.ProductID.smallTip: return "☕"
        case TipJarService.ProductID.mediumTip: return "🍕"
        case TipJarService.ProductID.largeTip: return "🎁"
        case TipJarService.ProductID.hugeTip: return "🚀"
        default: return "❤️"
        }
    }
}

// MARK: - Tip Card

struct TipCard: View {
    let product: Product
    let emoji: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text(emoji)
                    .font(.title)
                Text(product.displayPrice)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isSelected ? AppColors.primary : AppColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? AppColors.primaryDim : AppColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? AppColors.primary : AppColors.separator, lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}
