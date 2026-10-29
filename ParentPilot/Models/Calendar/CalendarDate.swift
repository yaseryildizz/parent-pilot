import Foundation

nonisolated struct CalendarDate: Hashable, Comparable, Sendable {
    let year: Int
    let month: Int
    let day: Int
    init(year: Int, month: Int, day: Int) throws {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.year = year
        components.month = month
        components.day = day
        guard components.date != nil else { throw CalendarModelError.invalidDate }
        self.year = year
        self.month = month
        self.day = day
    }

    static func < (lhs: CalendarDate, rhs: CalendarDate) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }
}

nonisolated struct LocalTime: Hashable, Comparable, Sendable {
    let hour: Int
    let minute: Int
    init(hour: Int, minute: Int) throws {
        guard (0...23).contains(hour), (0...59).contains(minute) else { throw CalendarModelError.invalidTime }
        self.hour = hour
        self.minute = minute
    }

    static func < (lhs: LocalTime, rhs: LocalTime) -> Bool {
        (lhs.hour, lhs.minute) < (rhs.hour, rhs.minute)
    }
}

nonisolated enum CalendarModelError: Error, Sendable {
    case invalidDate
    case invalidTime
}
