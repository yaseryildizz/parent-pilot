import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(AppTypography.buttonLabel).frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.medium).foregroundStyle(.white)
            .background(
                AppColors.accent.opacity(configuration.isPressed ? 0.78 : 1),
                in: RoundedRectangle(cornerRadius: AppRadius.medium)
            )
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(AppTypography.buttonLabel).frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.small).foregroundStyle(AppColors.accent)
            .background(
                AppColors.accentSoft.opacity(configuration.isPressed ? 0.65 : 1),
                in: RoundedRectangle(cornerRadius: AppRadius.medium)
            )
    }
}
