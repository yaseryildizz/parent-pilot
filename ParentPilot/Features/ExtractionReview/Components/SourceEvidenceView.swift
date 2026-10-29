import SwiftUI

struct SourceEvidenceView: View {
    let evidence: [SourceEvidence]
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Source").font(AppTypography.metadata.weight(.semibold))
                .foregroundStyle(AppColors.secondaryText)
            ForEach(Array(evidence.enumerated()), id: \.offset) { _, item in
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("“\(item.excerpt)”").font(AppTypography.secondaryBody).italic()
                        .fixedSize(horizontal: false, vertical: true)
                    if let page = item.pageNumber {
                        Label("Page \(page)", systemImage: "doc.text").font(AppTypography.metadata)
                            .foregroundStyle(AppColors.tertiaryText)
                    }
                }
                .padding(AppSpacing.medium)
                .background(AppColors.background, in: RoundedRectangle(cornerRadius: AppRadius.small))
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}
