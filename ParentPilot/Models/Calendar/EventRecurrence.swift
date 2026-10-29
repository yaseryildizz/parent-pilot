nonisolated enum SchoolWeekday: Int, Hashable, Sendable {
    case sunday = 1
    case monday, tuesday, wednesday, thursday, friday, saturday
}
nonisolated struct EventRecurrence: Equatable, Sendable {
    let weekdays: Set<SchoolWeekday>
    let startDate: CalendarDate?
    let endDate: CalendarDate?
    let exceptions: [RecurrenceException]
}
nonisolated enum RecurrenceExceptionKind: Equatable, Sendable {
    case cancelled
    case changedTime(EventTime)
    case replaced(SchoolEventID)
}
nonisolated struct RecurrenceException: Equatable, Sendable {
    let date: CalendarDate
    let kind: RecurrenceExceptionKind
    let provenance: CalendarProvenance
}
