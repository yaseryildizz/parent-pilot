nonisolated struct ReviewedCalendarCommitResult: Equatable, Sendable {
    let eventIDs: [SchoolEventID]
    let taskIDs: [TaskID]
    let reminderIntentIDs: [ReminderIntentID]
    let scheduleOverrideIDs: [ScheduleOverrideID]
    let skippedCandidates: [SkippedCalendarCandidate]
}

nonisolated struct ReviewedCalendarCommitService: Sendable {
    private let mapper: ReviewedExtractionMapper
    private let calendarStore: any CalendarStore

    init(
        mapper: ReviewedExtractionMapper,
        calendarStore: any CalendarStore
    ) {
        self.mapper = mapper
        self.calendarStore = calendarStore
    }

    func commit(_ reviewResult: ExtractionReviewResult) async throws -> ReviewedCalendarCommitResult {
        let mappingResult = mapper.map(reviewResult)
        try Task.checkCancellation()
        _ = try await calendarStore.save(mappingResult)

        return ReviewedCalendarCommitResult(
            eventIDs: mappingResult.events.map(\.id),
            taskIDs: mappingResult.tasks.map(\.id),
            reminderIntentIDs: mappingResult.reminderIntents.map(\.id),
            scheduleOverrideIDs: mappingResult.overrides.map(\.id),
            skippedCandidates: mappingResult.skippedCandidates
        )
    }
}
