import Foundation

nonisolated struct SourceEvidence: Equatable, Sendable {
    let sourceDocumentID: DocumentID
    let excerpt: String
    let pageNumber: Int?
    let characterRange: Range<Int>?

    init(
        sourceDocumentID: DocumentID,
        excerpt: String,
        pageNumber: Int? = nil,
        characterRange: Range<Int>? = nil
    ) throws {
        guard !excerpt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            pageNumber.map({ $0 > 0 }) ?? true,
            characterRange.map({ !$0.isEmpty && $0.lowerBound >= 0 }) ?? true
        else { throw DocumentModelError.invalidEvidence }
        self.sourceDocumentID = sourceDocumentID
        self.excerpt = excerpt
        self.pageNumber = pageNumber
        self.characterRange = characterRange
    }
}
