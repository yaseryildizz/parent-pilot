import Foundation

nonisolated enum DocumentsFeatureError: Equatable, Sendable {
    case unsupportedDocument
    case inaccessibleFile
    case fileTooLarge
    case uploadFailed
    case processingFailed
    case processingTimedOut
    case extractionUnavailable
    case cancelled

    var message: String {
        switch self {
        case .unsupportedDocument: "Choose a valid PDF document."
        case .inaccessibleFile:
            "ParentPilot could not access this file. Choose it again or select another PDF."
        case .fileTooLarge: "This PDF is larger than the supported upload limit."
        case .uploadFailed: "The PDF could not be uploaded. Check your connection and try again."
        case .processingFailed: "ParentPilot could not finish analyzing this document."
        case .processingTimedOut: "Analysis is taking longer than expected. You can check again."
        case .extractionUnavailable: "The extracted items are not available yet. Try again."
        case .cancelled: "The operation was cancelled."
        }
    }
}

nonisolated enum DocumentsRetryAction: Equatable, Sendable {
    case chooseAnother
    case upload
    case processing(SchoolDocument)
    case extraction(SchoolDocument)
}

nonisolated enum DocumentsViewState: Equatable, Sendable {
    case idle
    case selected(SelectedDocument)
    case uploading(SelectedDocument)
    case processing(SelectedDocument, SchoolDocument, DocumentProcessingStatus)
    case completed(SelectedDocument, SchoolDocument, ExtractionResult)
    case failed(SelectedDocument?, DocumentsFeatureError, DocumentsRetryAction)

    var selectedDocument: SelectedDocument? {
        switch self {
        case .idle: nil
        case .selected(let document), .uploading(let document): document
        case .processing(let document, _, _), .completed(let document, _, _): document
        case .failed(let document, _, _): document
        }
    }
}
