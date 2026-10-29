#if DEBUG
    import Foundation

    @MainActor
    enum PreviewFixtures {
        static let selected = SelectedDocument(
            id: UUID(),
            temporaryURL: URL(fileURLWithPath: "/tmp/Autumn Newsletter.pdf"),
            displayFilename: "Autumn Newsletter.pdf",
            fileSize: 1_840_000,
            mimeType: "application/pdf"
        )
        static let remote = SchoolDocument(
            id: .init(rawValue: "preview"),
            originalFilename: selected.displayFilename,
            uploadedAt: .now,
            source: .pdfUpload,
            scope: .unknown,
            processingStatus: .processing,
            context: .init()
        )
        static let evidence: SourceEvidence = {
            do {
                return try SourceEvidence(
                    sourceDocumentID: .init(rawValue: "preview"),
                    excerpt: "FS1 pupils will finish at 12:30 PM this Thursday.",
                    pageNumber: 2
                )
            } catch { preconditionFailure("Invalid source-evidence preview fixture: \(error)") }
        }()
        static let pickup: ExtractionCandidate = {
            do {
                return try ExtractionCandidate(
                    id: "pickup",
                    type: .pickupChange,
                    title: "Thursday pickup at 12:30 PM",
                    details: nil,
                    startsAt: .now,
                    endsAt: nil,
                    isAllDay: false,
                    confidence: try ExtractionConfidence(score: 0.91),
                    evidence: [evidence],
                    isScheduleOverride: true
                )
            } catch { preconditionFailure("Invalid pickup preview fixture: \(error)") }
        }()
        static let activity: ExtractionCandidate = {
            do {
                return try ExtractionCandidate(
                    id: "activity",
                    type: .activity,
                    title: "Bring PE kit on Tuesday",
                    details: nil,
                    startsAt: nil,
                    endsAt: nil,
                    isAllDay: true,
                    confidence: try ExtractionConfidence(score: 0.88),
                    evidence: [evidence]
                )
            } catch { preconditionFailure("Invalid activity preview fixture: \(error)") }
        }()
        static let extraction = ExtractionResult(
            documentID: .init(rawValue: "preview"),
            schemaVersion: "1",
            generatedAt: .now,
            origin: .newlyProcessed,
            candidates: [pickup, activity]
        )

        static func documents(_ state: DocumentsViewState) -> DocumentsView {
            let service = PreviewDocumentService()
            let config = AppConfiguration(environment: .development)
            let model = DocumentsViewModel(
                documentService: service,
                documentValidator: .init(maximumUploadBytes: config.maximumDocumentUploadBytes),
                processingMonitor: DocumentProcessingMonitor(documentService: service)
            )
            model.setPreviewState(state)
            return DocumentsView(viewModel: model)
        }
    }
#endif
