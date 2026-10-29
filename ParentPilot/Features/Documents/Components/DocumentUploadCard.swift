import SwiftUI

struct DocumentUploadCard: View {
    let choosePDF: () -> Void
    var body: some View {
        SurfaceCard {
            VStack(spacing: AppSpacing.large) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.medium).fill(AppColors.accentSoft)
                        .frame(width: 72, height: 72)
                    Image(systemName: "doc.text.fill").font(.system(size: 30, weight: .medium))
                        .foregroundStyle(AppColors.accent)
                }
                .accessibilityHidden(true)
                VStack(spacing: AppSpacing.small) {
                    Text("Choose a school PDF").font(AppTypography.sectionHeading)
                    Text("Timetables, newsletters, and school notices work well.")
                        .font(AppTypography.secondaryBody).foregroundStyle(AppColors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                Button("Choose PDF", action: choosePDF).buttonStyle(PrimaryButtonStyle())
                    .accessibilityHint("Opens the PDF file picker")
                Label("You’ll review the file before anything is analyzed.", systemImage: "lock.shield")
                    .font(AppTypography.metadata).foregroundStyle(AppColors.tertiaryText)
            }
            .frame(maxWidth: .infinity).padding(.vertical, AppSpacing.medium)
        }
    }
}
