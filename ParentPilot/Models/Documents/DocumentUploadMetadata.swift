nonisolated struct DocumentUploadMetadata: Equatable, Sendable {
    let scope: DocumentScope
    let context: DocumentContext

    init(scope: DocumentScope = .unknown, context: DocumentContext = DocumentContext()) {
        self.scope = scope
        self.context = context
    }
}
