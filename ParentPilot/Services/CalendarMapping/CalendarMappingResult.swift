nonisolated enum CalendarMappingSkipReason: Equatable, Sendable {
    case missingDate, missingTime, unsupportedType, conflictingReviewDecision
}
nonisolated struct SkippedCalendarCandidate: Equatable, Sendable {
    let candidateID: String
    let reason: CalendarMappingSkipReason
}
nonisolated struct CalendarMappingResult: Equatable, Sendable {
    var events: [SchoolEvent] = []
    var tasks: [SchoolTask] = []
    var reminderIntents: [ReminderIntent] = []
    var overrides: [ScheduleOverride] = []
    var skippedCandidates: [SkippedCalendarCandidate] = []
}
