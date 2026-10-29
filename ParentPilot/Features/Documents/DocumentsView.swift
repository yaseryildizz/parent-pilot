import SwiftUI
import UniformTypeIdentifiers

struct DocumentsView: View {
    @State
    private var viewModel: DocumentsViewModel
    @State
    private var isFileImporterPresented = false
    @State
    private var reviewViewModel: ExtractionReviewViewModel?

    init(viewModel: DocumentsViewModel) { _viewModel = State(initialValue: viewModel) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    header
                    content
                }
                .padding(.horizontal, AppSpacing.medium).padding(.vertical, AppSpacing.large)
                .frame(maxWidth: 640).frame(maxWidth: .infinity)
            }
            .background(AppColors.background)
        }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls): if let url = urls.first { viewModel.selectDocument(at: url) }
            case .failure(let error): viewModel.fileSelectionFailed(error)
            }
        }
        .sheet(item: $reviewViewModel) { ExtractionReviewView(viewModel: $0) }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("School documents").font(AppTypography.largeTitle).foregroundStyle(AppColors.primaryText)
            Text("Turn school PDFs into reminders and calendar items.").font(AppTypography.secondaryBody)
                .foregroundStyle(AppColors.secondaryText)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle: DocumentUploadCard(choosePDF: showFileImporter)
        case .selected(let document):
            SelectedDocumentRow(document: document)
            HStack {
                Button("Replace", action: showFileImporter).buttonStyle(SecondaryButtonStyle())
                Button("Analyze document", action: viewModel.analyzeSelectedDocument)
                    .buttonStyle(PrimaryButtonStyle())
            }
            .controlSize(.large)
        case .uploading(let document):
            SelectedDocumentRow(document: document)
            DocumentProcessingView(title: "Uploading document…", message: "This may take a moment.")
            cancelButton
        case .processing(let document, _, let status):
            SelectedDocumentRow(document: document)
            DocumentProcessingView(
                title: processingTitle(for: status),
                message: "We’re looking for dates, tasks, and important changes."
            )
            cancelButton
        case .completed(let document, _, let result):
            SelectedDocumentRow(document: document)
            SurfaceCard {
                VStack(spacing: AppSpacing.small) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 36))
                        .foregroundStyle(AppColors.success).accessibilityHidden(true)
                    Text("\(result.candidates.count) items found").font(AppTypography.sectionHeading)
                    Text("Review everything before anything is added.").font(AppTypography.secondaryBody)
                        .foregroundStyle(AppColors.secondaryText)
                }
                .frame(maxWidth: .infinity).padding(.vertical, AppSpacing.small)
            }
            .accessibilityElement(children: .combine)
            Button("Review \(result.candidates.count) items") {
                reviewViewModel = ExtractionReviewViewModel(extractionResult: result)
            }
            .buttonStyle(PrimaryButtonStyle())
            Button("Choose another PDF") {
                Task {
                    await viewModel.reset()
                    isFileImporterPresented = true
                }
            }
            .buttonStyle(.bordered).controlSize(.large)
        case .failed(let document, let error, let retryAction):
            if let document { SelectedDocumentRow(document: document) }
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Label("We couldn’t finish that", systemImage: "exclamationmark.triangle.fill")
                    .font(AppTypography.headline).foregroundStyle(AppColors.warning)
                Text(error.message).font(AppTypography.body).foregroundStyle(AppColors.primaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(AppSpacing.medium)
            .background(AppColors.warningSoft, in: RoundedRectangle(cornerRadius: AppRadius.medium))
            HStack {
                Button("Choose another", action: showFileImporter).buttonStyle(.bordered)
                Spacer()
                if retryAction != .chooseAnother {
                    Button("Try again", action: viewModel.retryProcessing).buttonStyle(PrimaryButtonStyle())
                }
            }
            .controlSize(.large)
        }
    }

    private var cancelButton: some View {
        Button("Cancel", role: .cancel, action: viewModel.cancelProcessing).buttonStyle(.bordered)
            .controlSize(.large).frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func showFileImporter() { isFileImporterPresented = true }

    private func processingTitle(for status: DocumentProcessingStatus) -> String {
        switch status {
        case .uploaded: "Document uploaded"
        case .queued: "Waiting to analyze"
        case .processing: "Analyzing school information…"
        case .completed: "Preparing results"
        case .failed: "Analysis failed"
        }
    }
}

#if DEBUG
    #Preview("Documents · Idle") { PreviewFixtures.documents(.idle) }
    #Preview("Documents · Selected") { PreviewFixtures.documents(.selected(PreviewFixtures.selected)) }
    #Preview("Documents · Processing") {
        PreviewFixtures.documents(.processing(PreviewFixtures.selected, PreviewFixtures.remote, .processing))
    }
    #Preview("Documents · Completed") {
        PreviewFixtures.documents(
            .completed(PreviewFixtures.selected, PreviewFixtures.remote, PreviewFixtures.extraction)
        )
    }
    #Preview("Documents · Failed") {
        PreviewFixtures.documents(.failed(PreviewFixtures.selected, .uploadFailed, .upload))
    }
#endif
