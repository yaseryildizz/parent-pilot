import Foundation
import Testing

@testable import ParentPilot

struct ReviewedCalendarCommitServiceTests {
    @Test
    func commitMapsAndPersistsReviewedCandidates() async throws {
        let store: any CalendarStore = InMemoryCalendarStore()
        let service = ReviewedCalendarCommitService(
            mapper: ReviewedExtractionMapper(),
            calendarStore: store
        )
        let acceptedCandidate = try makeCommitCandidate(id: "event", type: .event)
        let skippedCandidate = try makeCommitCandidate(id: "general", type: .general)
        let review = ExtractionReviewResult(
            documentID: DocumentID(rawValue: "document"),
            accepted: [acceptedCandidate, skippedCandidate],
            rejected: []
        )

        let result = try await service.commit(review)

        #expect(result.eventIDs == [SchoolEventID(rawValue: "candidate:event")])
        #expect(result.reminderIntentIDs == [ReminderIntentID(rawValue: "reminder:event")])
        #expect(result.skippedCandidates == [.init(candidateID: "general", reason: .unsupportedType)])
        #expect(try await store.fetchAllEvents().count == 1)
        #expect(try await store.fetchAllReminderIntents().count == 1)
    }

    @Test
    func repeatedCommitDoesNotDuplicateDataAndKeepsStableIdentities() async throws {
        let store: any CalendarStore = InMemoryCalendarStore()
        let mapper = ReviewedExtractionMapper()
        let service = ReviewedCalendarCommitService(mapper: mapper, calendarStore: store)
        let pickup = try makeCommitCandidate(id: "pickup", type: .pickupChange)
        let review = ExtractionReviewResult(
            documentID: DocumentID(rawValue: "document"),
            accepted: [pickup],
            rejected: []
        )

        let firstResult = try await service.commit(review)
        let secondResult = try await service.commit(review)
        let snapshot = try await store.snapshot()

        #expect(firstResult == secondResult)
        #expect(firstResult.scheduleOverrideIDs == [ScheduleOverrideID(rawValue: "override:pickup")])
        #expect(firstResult.reminderIntentIDs == [ReminderIntentID(rawValue: "reminder:pickup")])
        #expect(snapshot.scheduleOverrides.count == 1)
        #expect(snapshot.reminderIntents.count == 1)
    }
}

private func makeCommitCandidate(
    id: String,
    type: ExtractionCandidateType
) throws -> ExtractionCandidate {
    let date = try CalendarDate(year: 2026, month: 9, day: 10)
    let temporal = ExtractedTemporalInfo(
        date: date,
        startTime: type == .pickupChange ? try LocalTime(hour: 12, minute: 30) : nil,
        endTime: nil,
        timeZoneIdentifier: nil,
        recurrence: nil
    )
    return try ExtractionCandidate(
        id: id,
        type: type,
        title: "Candidate \(id)",
        details: nil,
        startsAt: nil,
        endsAt: nil,
        isAllDay: type != .pickupChange,
        confidence: ExtractionConfidence(score: 0.9),
        evidence: [
            SourceEvidence(
                sourceDocumentID: DocumentID(rawValue: "document"),
                excerpt: "Source evidence"
            )
        ],
        isScheduleOverride: type == .pickupChange,
        temporal: temporal
    )
}
