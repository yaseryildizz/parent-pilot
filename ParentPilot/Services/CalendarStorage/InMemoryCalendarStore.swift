actor InMemoryCalendarStore: CalendarStore {
    private var eventsByID: [SchoolEventID: SchoolEvent] = [:]
    private var tasksByID: [TaskID: SchoolTask] = [:]
    private var reminderIntentsByID: [ReminderIntentID: ReminderIntent] = [:]
    private var scheduleOverridesByID: [ScheduleOverrideID: ScheduleOverride] = [:]

    @discardableResult
    func save(_ mappingResult: CalendarMappingResult) throws -> CalendarStoreSnapshot {
        try validate(mappingResult)

        var updatedEvents = eventsByID
        var updatedTasks = tasksByID
        var updatedReminderIntents = reminderIntentsByID
        var updatedScheduleOverrides = scheduleOverridesByID

        mappingResult.events.forEach { updatedEvents[$0.id] = $0 }
        mappingResult.tasks.forEach { updatedTasks[$0.id] = $0 }
        mappingResult.reminderIntents.forEach { updatedReminderIntents[$0.id] = $0 }
        mappingResult.overrides.forEach { updatedScheduleOverrides[$0.id] = $0 }

        eventsByID = updatedEvents
        tasksByID = updatedTasks
        reminderIntentsByID = updatedReminderIntents
        scheduleOverridesByID = updatedScheduleOverrides

        return makeSnapshot()
    }

    func fetchAllEvents() -> [SchoolEvent] {
        sortedEvents(eventsByID.values)
    }

    func fetchEvents(in dateRange: ClosedRange<CalendarDate>) -> [SchoolEvent] {
        sortedEvents(
            eventsByID.values.filter { event in
                if dateRange.contains(event.time.calendarDate) {
                    return true
                }
                guard let recurrence = event.recurrence else {
                    return false
                }
                let recurrenceStart = recurrence.startDate ?? event.time.calendarDate
                let startsBeforeRangeEnds = recurrenceStart <= dateRange.upperBound
                let endsAfterRangeStarts = recurrence.endDate.map { $0 >= dateRange.lowerBound } ?? true
                return startsBeforeRangeEnds && endsAfterRangeStarts
            }
        )
    }

    func fetchAllTasks() -> [SchoolTask] {
        tasksByID.values.sorted(by: tasksAreOrdered)
    }

    func fetchAllReminderIntents() -> [ReminderIntent] {
        reminderIntentsByID.values.sorted { $0.id.rawValue < $1.id.rawValue }
    }

    func fetchAllScheduleOverrides() -> [ScheduleOverride] {
        scheduleOverridesByID.values.sorted {
            if $0.targetDate != $1.targetDate {
                return $0.targetDate < $1.targetDate
            }
            return $0.id.rawValue < $1.id.rawValue
        }
    }

    func snapshot() -> CalendarStoreSnapshot {
        makeSnapshot()
    }

    func remove(_ identity: CalendarStoredItemIdentity) {
        switch identity {
        case .event(let id):
            eventsByID[id] = nil
        case .task(let id):
            tasksByID[id] = nil
        case .reminderIntent(let id):
            reminderIntentsByID[id] = nil
        case .scheduleOverride(let id):
            scheduleOverridesByID[id] = nil
        }
    }

    func clear() {
        eventsByID.removeAll()
        tasksByID.removeAll()
        reminderIntentsByID.removeAll()
        scheduleOverridesByID.removeAll()
    }

    private func validate(_ mappingResult: CalendarMappingResult) throws {
        try validateItems(
            mappingResult.events,
            kind: .event,
            identity: { $0.id.rawValue }
        )
        try validateItems(
            mappingResult.tasks,
            kind: .task,
            identity: { $0.id.rawValue }
        )
        try validateItems(
            mappingResult.reminderIntents,
            kind: .reminderIntent,
            identity: { $0.id.rawValue }
        )
        try validateItems(
            mappingResult.overrides,
            kind: .scheduleOverride,
            identity: { $0.id.rawValue }
        )
    }

    private func validateItems<Item: Equatable>(
        _ items: [Item],
        kind: CalendarStoredItemKind,
        identity: (Item) -> String
    ) throws {
        var itemsByIdentity: [String: Item] = [:]
        for item in items {
            let itemIdentity = identity(item)
            guard !itemIdentity.isEmpty else {
                throw CalendarStoreError.invalidIdentity(kind: kind)
            }
            if let existingItem = itemsByIdentity[itemIdentity], existingItem != item {
                throw CalendarStoreError.duplicateIdentityConflict(
                    kind: kind,
                    identity: itemIdentity
                )
            }
            itemsByIdentity[itemIdentity] = item
        }
    }

    private func makeSnapshot() -> CalendarStoreSnapshot {
        CalendarStoreSnapshot(
            events: fetchAllEvents(),
            tasks: fetchAllTasks(),
            reminderIntents: fetchAllReminderIntents(),
            scheduleOverrides: fetchAllScheduleOverrides()
        )
    }

    private func sortedEvents<S: Sequence>(_ events: S) -> [SchoolEvent] where S.Element == SchoolEvent {
        events.sorted {
            if $0.time.calendarDate != $1.time.calendarDate {
                return $0.time.calendarDate < $1.time.calendarDate
            }
            if $0.time.sortTime != $1.time.sortTime {
                return timesAreOrdered($0.time.sortTime, $1.time.sortTime)
            }
            return $0.id.rawValue < $1.id.rawValue
        }
    }

    private func tasksAreOrdered(_ lhs: SchoolTask, _ rhs: SchoolTask) -> Bool {
        switch (lhs.due, rhs.due) {
        case (let lhsDue?, let rhsDue?):
            if lhsDue.calendarDate != rhsDue.calendarDate {
                return lhsDue.calendarDate < rhsDue.calendarDate
            }
            if lhsDue.sortTime != rhsDue.sortTime {
                return timesAreOrdered(lhsDue.sortTime, rhsDue.sortTime)
            }
            return lhs.id.rawValue < rhs.id.rawValue
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            return lhs.id.rawValue < rhs.id.rawValue
        }
    }

    private func timesAreOrdered(_ lhs: LocalTime?, _ rhs: LocalTime?) -> Bool {
        switch (lhs, rhs) {
        case (let lhs?, let rhs?):
            return lhs < rhs
        case (nil, _?):
            return true
        case (_?, nil), (nil, nil):
            return false
        }
    }
}

nonisolated extension EventTime {
    fileprivate var calendarDate: CalendarDate {
        switch self {
        case .dateOnly(let date):
            date
        case .localDateTime(let date, _, _, _):
            date
        }
    }

    fileprivate var sortTime: LocalTime? {
        switch self {
        case .dateOnly:
            nil
        case .localDateTime(_, let start, _, _):
            start
        }
    }
}
