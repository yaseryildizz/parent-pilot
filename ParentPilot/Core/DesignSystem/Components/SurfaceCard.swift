import SwiftUI

struct SurfaceCard<Content: View>: View {
    @ViewBuilder
    let content: Content
    var body: some View {
        content.frame(maxWidth: .infinity, alignment: .leading).padding(AppSpacing.medium)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
            .overlay(RoundedRectangle(cornerRadius: AppRadius.large).stroke(AppColors.divider, lineWidth: 1))
    }
}
