import SwiftUI

struct ExtractionReviewView: View {
    @State
    private var viewModel: ExtractionReviewViewModel
    @Environment(\.dismiss)
    private var dismiss

    init(viewModel: ExtractionReviewViewModel) { _viewModel = State(initialValue: viewModel) }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.candidates.isEmpty {
                    ContentUnavailableView(
                        "Nothing to review",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("No actionable school information was found in this document.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: AppSpacing.medium) {
                            VStack(alignment: .leading, spacing: AppSpacing.small) {
                                Text("Review school updates").font(AppTypography.largeTitle)
                                Text("Check what ParentPilot found before adding anything.")
                                    .font(AppTypography.secondaryBody)
                                    .foregroundStyle(AppColors.secondaryText)
                            }
                            .padding(.bottom, AppSpacing.small)
                            ReviewSummaryView(summary: viewModel.summary)
                            HStack {
                                Button("Accept safe items", action: viewModel.acceptSafeItems)
                                    .buttonStyle(SecondaryButtonStyle())
                                Button("Reject all", role: .destructive, action: viewModel.rejectAll)
                                    .font(AppTypography.buttonLabel)
                            }
                            ForEach(viewModel.candidates) { item in
                                ExtractionCandidateRow(
                                    item: item,
                                    needsAttention: viewModel.requiresAttention(item),
                                    decide: { viewModel.decide($0, candidateID: item.id) },
                                    toggleEvidence: { viewModel.toggleEvidence(candidateID: item.id) }
                                )
                            }
                        }
                        .padding(AppSpacing.medium).padding(.bottom, 120)
                    }
                    .background(AppColors.background)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: dismiss.callAsFunction)
                }
            }
            .safeAreaInset(edge: .bottom) { if !viewModel.candidates.isEmpty { confirmationBar } }
        }
    }

    private var confirmationBar: some View {
        VStack(spacing: AppSpacing.small) {
            Text(
                "\(viewModel.summary.accepted) accepted · \(viewModel.summary.rejected) rejected · \(viewModel.summary.unresolved) remaining"
            )
            .font(AppTypography.metadata).foregroundStyle(AppColors.secondaryText)
            Button("Confirm review", action: confirmReview).buttonStyle(PrimaryButtonStyle())
                .disabled(!viewModel.canConfirm).opacity(viewModel.canConfirm ? 1 : 0.48)
            if !viewModel.canConfirm {
                Text("Review every item to continue.").font(AppTypography.metadata)
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
        .padding(.horizontal, AppSpacing.medium).padding(.vertical, AppSpacing.small).background(.bar)
        .overlay(alignment: .top) { Divider() }
    }

    private func confirmReview() {
        guard viewModel.confirmReview() != nil else { return }
        dismiss()
    }
}

#if DEBUG
    #Preview("Review · Mixed") {
        ExtractionReviewView(
            viewModel: ExtractionReviewViewModel(extractionResult: PreviewFixtures.extraction)
        )
    }
    #Preview("Review · Empty") {
        ExtractionReviewView(
            viewModel: ExtractionReviewViewModel(
                extractionResult: ExtractionResult(
                    documentID: .init(rawValue: "empty"),
                    schemaVersion: "1",
                    generatedAt: .now,
                    origin: .newlyProcessed,
                    candidates: []
                )
            )
        )
    }
#endif
