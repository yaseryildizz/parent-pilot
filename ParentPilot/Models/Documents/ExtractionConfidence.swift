nonisolated struct ExtractionConfidence: Equatable, Comparable, Sendable {
    let score: Double

    init(score: Double) throws {
        guard score.isFinite, (0...1).contains(score) else { throw DocumentModelError.invalidConfidence }
        self.score = score
    }

    static func < (lhs: ExtractionConfidence, rhs: ExtractionConfidence) -> Bool { lhs.score < rhs.score }
}
