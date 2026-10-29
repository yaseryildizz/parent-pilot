nonisolated enum CalendarStoredItemKind: String, Equatable, Sendable {
    case event
    case task
    case reminderIntent
    case scheduleOverride
}

nonisolated enum CalendarStoreError: Error, Equatable, Sendable {
    case duplicateIdentityConflict(kind: CalendarStoredItemKind, identity: String)
    case invalidIdentity(kind: CalendarStoredItemKind)
}
