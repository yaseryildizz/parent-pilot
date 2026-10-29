nonisolated struct ExtractedTemporalInfoDTO: Decodable, Sendable {
    let date: String
    let startTime: String?
    let endTime: String?
    let timeZoneIdentifier: String?
    let recurrenceWeekdays: [Int]?
    let recurrenceEndDate: String?
}
