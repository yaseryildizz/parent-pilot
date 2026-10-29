nonisolated struct ExtractedTemporalInfo: Equatable, Sendable {
    let date: CalendarDate
    let startTime: LocalTime?
    let endTime: LocalTime?
    let timeZoneIdentifier: String?
    let recurrence: EventRecurrence?
    var eventTime: EventTime {
        if let startTime {
            .localDateTime(date: date, start: startTime, end: endTime, timeZoneIdentifier: timeZoneIdentifier)
        } else {
            .dateOnly(date)
        }
    }
}
