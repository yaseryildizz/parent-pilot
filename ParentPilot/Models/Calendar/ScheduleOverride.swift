nonisolated struct ScheduleOverrideID: RawRepresentable, Hashable, Sendable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }
}

nonisolated enum ScheduleOverrideType: String, Sendable {
    case pickupChange, changedTime, cancellation, replacement
}
nonisolated struct ScheduleOverride: Equatable, Sendable {
    let id: ScheduleOverrideID
    let type: ScheduleOverrideType
    let targetDate: CalendarDate
    let affectedEventID: SchoolEventID?
    let previousTime: LocalTime?
    let newTime: LocalTime?
    let reason: String?
    let provenance: CalendarProvenance
    let context: DocumentContext
}
