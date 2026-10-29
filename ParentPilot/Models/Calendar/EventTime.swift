nonisolated enum EventTime: Equatable, Sendable {
    case dateOnly(CalendarDate)
    case localDateTime(date: CalendarDate, start: LocalTime, end: LocalTime?, timeZoneIdentifier: String?)
}
