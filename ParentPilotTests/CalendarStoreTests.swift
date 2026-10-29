import Foundation
import Testing

@testable import ParentPilot

struct CalendarStoreTests {
    @Test
    func saveAndFetchEvent() async throws {
        let store: any CalendarStore = InMemoryCalendarStore()
        let event = try makeEvent(id: "event-1", day: 10)

        _ = try await store.save(mapping(events: [event]))

        #expect(try await store.fetchAllEvents() == [event])
    }

    @Test
    func repeatedSaveIsIdempotent() async throws {
        let store: any CalendarStore = InMemoryCalendarStore()
        let result = try completeMappingResult()

        let firstSnapshot = try await store.save(result)
        let secondSnapshot = try await store.save(result)

        #expect(firstSnapshot == secondSnapshot)
        #expect(secondSnapshot.events.count == 1)
        #expect(secondSnapshot.tasks.count == 1)
        #expect(secondSnapshot.reminderIntents.count == 1)
        #expect(secondSnapshot.scheduleOverrides.count == 1)
    }

    @Test
    func sameIdentityUpdatesStoredValue() async throws {
        let store: any CalendarStore = InMemoryCalendarStore()
        let original = try makeEvent(id: "event-1", title: "Original", day: 10)
        let updated = try makeEvent(id: "event-1", title: "Updated", day: 11)

        _ = try await store.save(mapping(events: [original]))
        _ = try await store.save(mapping(events: [updated]))

        #expect(try await store.fetchAllEvents() == [updated])
    }

    @Test
    func queriesUseDeterministicDomainOrdering() async throws {
        let store: any CalendarStore = InMemoryCalendarStore()
        let laterEvent = try makeEvent(id: "event-z", day: 12)
        let firstSameDayEvent = try makeEvent(id: "event-a", day: 10)
        let secondSameDayEvent = try makeEvent(id: "event-b", day: 10)
        let dueTask = try makeTask(id: "task-z", day: 9)
        let undatedTask = try makeTask(id: "task-a")
        let laterOverride = try makeOverride(id: "override-z", day: 15)
        let earlierOverride = try makeOverride(id: "override-a", day: 8)
        var result = CalendarMappingResult()
        result.events = [laterEvent, secondSameDayEvent, firstSameDayEvent]
        result.tasks = [undatedTask, dueTask]
        result.overrides = [laterOverride, earlierOverride]

        _ = try await store.save(result)

        #expect(try await store.fetchAllEvents().map(\.id.rawValue) == ["event-a", "event-b", "event-z"])
        #expect(try await store.fetchAllTasks().map(\.id.rawValue) == ["task-z", "task-a"])
        #expect(
            try await store.fetchAllScheduleOverrides().map(\.id.rawValue)
                == ["override-a", "override-z"]
        )
    }

    @Test
    func dateRangeIncludesDateOnlyAndStoredRecurringDefinitions() async throws {
        let store: any CalendarStore = InMemoryCalendarStore()
        let dateOnly = try makeEvent(id: "date-only", day: 10)
        let recurring = try makeEvent(
            id: "recurring",
            day: 1,
            recurrence: EventRecurrence(
                weekdays: [.monday],
                startDate: makeDate(day: 1),
                endDate: makeDate(day: 30),
                exceptions: []
            )
        )
        _ = try await store.save(mapping(events: [recurring, dateOnly]))

        let events = try await store.fetchEvents(in: makeDate(day: 10)...makeDate(day: 12))

        #expect(events.map(\.id.rawValue) == ["recurring", "date-only"])
    }

    @Test
    func saveAndFetchTasksRemindersAndOverrides() async throws {
        let store: any CalendarStore = InMemoryCalendarStore()
        let result = try completeMappingResult()

        _ = try await store.save(result)

        #expect(try await store.fetchAllTasks() == result.tasks)
        #expect(try await store.fetchAllReminderIntents() == result.reminderIntents)
        #expect(try await store.fetchAllScheduleOverrides() == result.overrides)
    }

    @Test
    func removeAndClearDeleteRequestedItems() async throws {
        let store: any CalendarStore = InMemoryCalendarStore()
        let result = try completeMappingResult()
        _ = try await store.save(result)

        try await store.remove(.event(result.events[0].id))
        try await store.remove(.task(result.tasks[0].id))
        try await store.remove(.reminderIntent(result.reminderIntents[0].id))
        try await store.remove(.scheduleOverride(result.overrides[0].id))

        #expect(try await store.snapshot() == .empty)

        _ = try await store.save(result)
        try await store.clear()
        #expect(try await store.snapshot() == .empty)
    }

    @Test
    func conflictingBatchFailsWithoutPartialState() async throws {
        let store: any CalendarStore = InMemoryCalendarStore()
        let existingEvent = try makeEvent(id: "existing", day: 1)
        _ = try await store.save(mapping(events: [existingEvent]))
        let snapshotBeforeFailure = try await store.snapshot()
        let conflictingEvent = try makeEvent(id: "conflict", title: "First", day: 2)
        let conflictingUpdate = try makeEvent(id: "conflict", title: "Second", day: 3)
        var invalidResult = CalendarMappingResult()
        invalidResult.events = [conflictingEvent, conflictingUpdate]
        invalidResult.tasks = [try makeTask(id: "should-not-save")]

        await #expect(throws: CalendarStoreError.self) {
            _ = try await store.save(invalidResult)
        }
        #expect(try await store.snapshot() == snapshotBeforeFailure)
    }

    @Test
    func concurrentSavesRemainCompleteAndDeterministic() async throws {
        let store: any CalendarStore = InMemoryCalendarStore()

        try await withThrowingTaskGroup(of: Void.self) { group in
            for index in 0..<20 {
                group.addTask {
                    var result = CalendarMappingResult()
                    result.tasks = [try makeTask(id: String(format: "task-%02d", index))]
                    _ = try await store.save(result)
                }
            }
            try await group.waitForAll()
        }

        #expect(
            try await store.fetchAllTasks().map(\.id.rawValue)
                == (0..<20).map { String(format: "task-%02d", $0) }
        )
    }
}

private func mapping(events: [SchoolEvent]) -> CalendarMappingResult {
    var result = CalendarMappingResult()
    result.events = events
    return result
}

private func completeMappingResult() throws -> CalendarMappingResult {
    let event = try makeEvent(id: "event-1", day: 10)
    let task = try makeTask(id: "task-1", day: 11)
    let override = try makeOverride(id: "override-1", day: 12)
    let reminder = ReminderIntent(
        id: ReminderIntentID(rawValue: "reminder-1"),
        target: .event(event.id),
        leadTime: .seconds(900),
        provenance: provenance
    )
    var result = CalendarMappingResult()
    result.events = [event]
    result.tasks = [task]
    result.reminderIntents = [reminder]
    result.overrides = [override]
    return result
}

private func makeEvent(
    id: String,
    title: String = "School event",
    day: Int,
    recurrence: EventRecurrence? = nil
) throws -> SchoolEvent {
    SchoolEvent(
        id: SchoolEventID(rawValue: id),
        title: title,
        time: .dateOnly(try makeDate(day: day)),
        type: .event,
        recurrence: recurrence,
        provenance: provenance,
        context: .init()
    )
}

private func makeTask(id: String, day: Int? = nil) throws -> SchoolTask {
    let due: EventTime?
    if let day {
        due = .dateOnly(try makeDate(day: day))
    } else {
        due = nil
    }
    return SchoolTask(
        id: TaskID(rawValue: id),
        title: "School task",
        due: due,
        provenance: provenance,
        context: .init()
    )
}

private func makeOverride(id: String, day: Int) throws -> ScheduleOverride {
    ScheduleOverride(
        id: ScheduleOverrideID(rawValue: id),
        type: .pickupChange,
        targetDate: try makeDate(day: day),
        affectedEventID: nil,
        previousTime: nil,
        newTime: try LocalTime(hour: 12, minute: 30),
        reason: nil,
        provenance: provenance,
        context: .init()
    )
}

private func makeDate(day: Int) throws -> CalendarDate {
    try CalendarDate(year: 2026, month: 9, day: day)
}

private let provenance = CalendarProvenance(
    extractionCandidateID: "candidate-1",
    evidence: []
)
