nonisolated struct CalendarStoreSnapshot: Equatable, Sendable {
    let events: [SchoolEvent]
    let tasks: [SchoolTask]
    let reminderIntents: [ReminderIntent]
    let scheduleOverrides: [ScheduleOverride]

    static let empty = CalendarStoreSnapshot(
        events: [],
        tasks: [],
        reminderIntents: [],
        scheduleOverrides: []
    )
}
