import Foundation
import Testing

@testable import ParentPilot

struct ReviewedExtractionMapperTests {
    @Test
    func mapsAcceptedItemsAndIgnoresRejected() throws {
        let event = try candidate("event", .event, temporal: temporal(time: nil))
        let holiday = try candidate("holiday", .holiday, temporal: temporal(time: nil))
        let payment = try candidate(
            "payment",
            .payment,
            temporal: temporal(time: try LocalTime(hour: 9, minute: 0))
        )
        let rejected = try candidate("rejected", .activity, temporal: temporal(time: nil))
        let result = ReviewedExtractionMapper()
            .map(
                .init(
                    documentID: .init(rawValue: "doc"),
                    accepted: [event, holiday, payment],
                    rejected: [rejected]
                )
            )
        #expect(result.events.count == 2)
        #expect(result.events[1].type == .holiday)
        #expect(result.tasks.count == 1)
        #expect(!result.events.contains { $0.provenance.extractionCandidateID == "rejected" })
        #expect(result.tasks[0].provenance.evidence[0].excerpt == "source")
        #expect(result.reminderIntents.count == 3)
    }

    @Test
    func pickupOverrideNeverFabricatesPreviousTime() throws {
        let pickup = try candidate(
            "pickup",
            .pickupChange,
            temporal: temporal(time: try LocalTime(hour: 12, minute: 30))
        )
        let result = ReviewedExtractionMapper()
            .map(.init(documentID: .init(rawValue: "doc"), accepted: [pickup], rejected: []))
        let expectedTime = try LocalTime(hour: 12, minute: 30)
        #expect(result.overrides[0].previousTime == nil)
        #expect(result.overrides[0].newTime == expectedTime)
        #expect(result.reminderIntents.count == 1)
    }

    @Test
    func incompleteAndUnsupportedCandidatesAreSkipped() throws {
        let event = try candidate("missing", .event, temporal: nil)
        let general = try candidate("general", .general, temporal: nil)
        let result = ReviewedExtractionMapper()
            .map(.init(documentID: .init(rawValue: "doc"), accepted: [event, general], rejected: []))
        #expect(
            result.skippedCandidates == [
                .init(candidateID: "missing", reason: .missingDate),
                .init(candidateID: "general", reason: .unsupportedType),
            ]
        )
        #expect(result.reminderIntents.isEmpty)
    }

    @Test
    func recurrenceAndExceptionsRemainModeled() throws {
        let provenance = CalendarProvenance(extractionCandidateID: "x", evidence: [])
        let date = try CalendarDate(year: 2026, month: 9, day: 8)
        let recurrence = EventRecurrence(
            weekdays: [.tuesday, .thursday],
            startDate: date,
            endDate: nil,
            exceptions: [.init(date: date, kind: .cancelled, provenance: provenance)]
        )
        let item = try candidate(
            "repeat",
            .activity,
            temporal: .init(
                date: date,
                startTime: nil,
                endTime: nil,
                timeZoneIdentifier: nil,
                recurrence: recurrence
            )
        )
        let result = ReviewedExtractionMapper()
            .map(.init(documentID: .init(rawValue: "doc"), accepted: [item], rejected: []))
        #expect(result.events[0].recurrence?.weekdays == [.tuesday, .thursday])
        #expect(result.events[0].recurrence?.exceptions.count == 1)
    }

    @Test
    func conflictingConfirmedDecisionFailsSafely() throws {
        let item = try candidate("same", .task, temporal: nil)
        let result = ReviewedExtractionMapper()
            .map(.init(documentID: .init(rawValue: "doc"), accepted: [item], rejected: [item]))
        #expect(result.tasks.isEmpty)
        #expect(result.skippedCandidates[0].reason == .conflictingReviewDecision)
    }

    private func temporal(time: LocalTime?) throws -> ExtractedTemporalInfo {
        .init(
            date: try CalendarDate(year: 2026, month: 9, day: 10),
            startTime: time,
            endTime: nil,
            timeZoneIdentifier: nil,
            recurrence: nil
        )
    }
    private func candidate(_ id: String, _ type: ExtractionCandidateType, temporal: ExtractedTemporalInfo?)
        throws -> ExtractionCandidate
    {
        try .init(
            id: id,
            type: type,
            title: id,
            details: nil,
            startsAt: nil,
            endsAt: nil,
            isAllDay: temporal?.startTime == nil,
            confidence: ExtractionConfidence(score: 0.9),
            evidence: [SourceEvidence(sourceDocumentID: .init(rawValue: "doc"), excerpt: "source")],
            temporal: temporal
        )
    }
}
