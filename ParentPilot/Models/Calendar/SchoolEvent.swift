nonisolated struct SchoolEventID: RawRepresentable, Hashable, Sendable {
    let rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}
nonisolated enum SchoolEventType: String, Sendable { case event, holiday, activity }
nonisolated struct SchoolEvent: Equatable, Sendable {
    let id: SchoolEventID
    let title: String
    let time: EventTime
    let type: SchoolEventType
    let recurrence: EventRecurrence?
    let provenance: CalendarProvenance
    let context: DocumentContext
}
