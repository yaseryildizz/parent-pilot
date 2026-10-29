import SwiftUI

struct ReviewSummaryView: View {
    let summary: ExtractionReviewSummary
    var body: some View {
        SurfaceCard {
            HStack(spacing: AppSpacing.small) {
                metric("Total", summary.accepted + summary.rejected + summary.unresolved)
                Divider()
                metric("Accepted", summary.accepted)
                Divider()
                metric("Needs review", summary.unresolved)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .combine)
    }
    private func metric(_ label: String, _ value: Int) -> some View {
        VStack(spacing: AppSpacing.extraSmall) {
            Text("\(value)").font(AppTypography.sectionHeading)
            Text(label).font(AppTypography.metadata).foregroundStyle(AppColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
