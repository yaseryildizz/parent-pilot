import Foundation

nonisolated struct DocumentID: RawRepresentable, Hashable, Codable, Sendable {
    let rawValue: String

    init(rawValue: String) { self.rawValue = rawValue }
}
