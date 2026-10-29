import SwiftUI

struct DocumentProcessingView: View {
    let title: String
    let message: String
    var body: some View {
        SurfaceCard {
            HStack(spacing: AppSpacing.medium) {
                ProgressView().controlSize(.large).tint(AppColors.accent).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: AppSpacing.extraSmall) {
                    Text(title).font(AppTypography.cardTitle)
                    Text(message).font(AppTypography.secondaryBody).foregroundStyle(AppColors.secondaryText)
                }
            }
            .padding(.vertical, AppSpacing.small).accessibilityElement(children: .combine)
            .accessibilityLabel("\(title). \(message)")
        }
    }
}
