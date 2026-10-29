import SwiftUI

struct ConfidenceBadge: View {
    let needsAttention: Bool
    var body: some View {
        Label(
            needsAttention ? "Needs your review" : "High confidence",
            systemImage: needsAttention ? "exclamationmark.circle.fill" : "checkmark.circle.fill"
        )
        .font(AppTypography.metadata.weight(.semibold))
        .foregroundStyle(needsAttention ? AppColors.warning : AppColors.success)
        .padding(.horizontal, AppSpacing.small).padding(.vertical, AppSpacing.extraSmall)
        .background(needsAttention ? AppColors.warningSoft : AppColors.successSoft, in: Capsule())
        .accessibilityLabel(
            needsAttention
                ? "Needs your review. Confidence is advisory." : "High confidence. Confidence is advisory."
        )
    }
}
