nonisolated struct ReminderIntentID: RawRepresentable, Hashable, Sendable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }
}

nonisolated enum ReminderTarget: Equatable, Sendable {
    case event(SchoolEventID)
    case task(TaskID)
    case scheduleOverride(ScheduleOverrideID)
}

nonisolated struct ReminderIntent: Equatable, Sendable {
    let id: ReminderIntentID
    let target: ReminderTarget
    let leadTime: Duration
    let provenance: CalendarProvenance
}
