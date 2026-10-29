import SwiftUI

struct ExtractionCandidateRow: View {
    let item: ReviewableExtractionCandidate
    let needsAttention: Bool
    let decide: (ExtractionReviewDecision) -> Void
    let toggleEvidence: () -> Void
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                HStack(alignment: .top, spacing: AppSpacing.medium) {
                    Image(systemName: icon).font(.title3.weight(.semibold)).foregroundStyle(AppColors.accent)
                        .frame(width: 40, height: 40)
                        .background(AppColors.accentSoft, in: RoundedRectangle(cornerRadius: AppRadius.small))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: AppSpacing.extraSmall) {
                        Text(typeLabel).font(AppTypography.metadata.weight(.semibold))
                            .foregroundStyle(AppColors.secondaryText)
                        Text(item.candidate.title).font(AppTypography.cardTitle)
                            .fixedSize(horizontal: false, vertical: true)
                        if let date = item.candidate.startsAt {
                            Text(date.formatted(date: .abbreviated, time: .shortened))
                                .font(AppTypography.secondaryBody).foregroundStyle(AppColors.secondaryText)
                        }
                    }
                }
                ConfidenceBadge(needsAttention: needsAttention)
                if item.candidate.isScheduleOverride || item.candidate.type == .pickupChange {
                    Label(
                        "Proposed schedule change",
                        systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90"
                    )
                    .font(AppTypography.secondaryBody.weight(.semibold)).foregroundStyle(AppColors.warning)
                }
                HStack(spacing: AppSpacing.small) {
                    decisionButton(
                        "Accept",
                        icon: "checkmark",
                        decision: .accepted,
                        selected: item.decision == .accepted
                    )
                    decisionButton(
                        "Reject",
                        icon: "xmark",
                        decision: .rejected,
                        selected: item.decision == .rejected
                    )
                }
                Button {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2), toggleEvidence)
                } label: {
                    Label(
                        item.isEvidenceExpanded ? "Hide source" : "View source",
                        systemImage: item.isEvidenceExpanded ? "chevron.up" : "quote.bubble"
                    )
                }
                .font(AppTypography.secondaryBody.weight(.semibold))
                if item.isEvidenceExpanded { SourceEvidenceView(evidence: item.candidate.evidence) }
            }
        }
        .opacity(item.decision == .rejected ? 0.68 : 1)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.large)
                .stroke(borderColor, lineWidth: item.decision == .undecided ? 0 : 2)
        )
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: item.decision)
    }

    private func decisionButton(
        _ title: String,
        icon: String,
        decision: ExtractionReviewDecision,
        selected: Bool
    ) -> some View {
        Button {
            decide(selected ? .undecided : decision)
        } label: {
            Label(title, systemImage: selected ? "\(icon).circle.fill" : "\(icon).circle")
                .frame(maxWidth: .infinity).padding(.vertical, AppSpacing.small)
        }
        .font(AppTypography.buttonLabel).foregroundStyle(selected ? .white : AppColors.primaryText)
        .background(
            selected
                ? (decision == .accepted ? AppColors.success : AppColors.destructive) : AppColors.background,
            in: RoundedRectangle(cornerRadius: AppRadius.small)
        )
        .accessibilityValue(selected ? "Selected" : "Not selected")
    }
    private var borderColor: Color { item.decision == .accepted ? AppColors.success : AppColors.destructive }
    private var typeLabel: String {
        item.candidate.type == .pickupChange ? "PICKUP CHANGE" : item.candidate.type.rawValue.uppercased()
    }
    private var icon: String {
        switch item.candidate.type {
        case .pickupChange: "clock.badge.exclamationmark"
        case .payment: "creditcard"
        case .holiday: "calendar.badge.minus"
        case .activity: "figure.run"
        case .task: "checklist"
        case .reminder: "bell"
        default: "calendar"
        }
    }
}
