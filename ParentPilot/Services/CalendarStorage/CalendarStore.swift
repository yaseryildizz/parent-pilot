nonisolated enum CalendarStoredItemIdentity: Hashable, Sendable {
    case event(SchoolEventID)
    case task(TaskID)
    case reminderIntent(ReminderIntentID)
    case scheduleOverride(ScheduleOverrideID)
}

nonisolated protocol CalendarStore: Sendable {
    @discardableResult
    func save(_ mappingResult: CalendarMappingResult) async throws -> CalendarStoreSnapshot

    func fetchAllEvents() async throws -> [SchoolEvent]
    func fetchEvents(in dateRange: ClosedRange<CalendarDate>) async throws -> [SchoolEvent]
    func fetchAllTasks() async throws -> [SchoolTask]
    func fetchAllReminderIntents() async throws -> [ReminderIntent]
    func fetchAllScheduleOverrides() async throws -> [ScheduleOverride]
    func snapshot() async throws -> CalendarStoreSnapshot
    func remove(_ identity: CalendarStoredItemIdentity) async throws
    func clear() async throws
}
