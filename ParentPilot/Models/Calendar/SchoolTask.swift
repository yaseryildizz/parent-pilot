nonisolated struct TaskID: RawRepresentable, Hashable, Sendable {
    let rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}
nonisolated struct SchoolTask: Equatable, Sendable {
    let id: TaskID
    let title: String
    let due: EventTime?
    let provenance: CalendarProvenance
    let context: DocumentContext
}
