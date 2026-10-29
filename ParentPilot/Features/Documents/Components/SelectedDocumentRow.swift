import SwiftUI

struct SelectedDocumentRow: View {
    let document: SelectedDocument
    var body: some View {
        SurfaceCard {
            HStack(spacing: AppSpacing.medium) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.small).fill(AppColors.destructiveSoft)
                        .frame(width: 48, height: 56)
                    Text("PDF").font(.caption2.bold()).foregroundStyle(AppColors.destructive)
                }
                VStack(alignment: .leading, spacing: AppSpacing.extraSmall) {
                    Text(document.displayFilename).font(AppTypography.cardTitle)
                        .foregroundStyle(AppColors.primaryText).fixedSize(horizontal: false, vertical: true)
                    Text(fileSize).font(AppTypography.metadata).foregroundStyle(AppColors.secondaryText)
                }
                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Selected PDF, \(document.displayFilename), \(fileSize)")
        }
    }
    private var fileSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(document.fileSize), countStyle: .file)
    }
}
