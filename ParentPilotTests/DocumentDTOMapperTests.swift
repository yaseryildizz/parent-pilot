import Foundation
import Testing

@testable import ParentPilot

struct DocumentDTOMapperTests {
    @Test
    func mapsExtractionResultWithRequiredEvidence() throws {
        let dto = ExtractionResultDTO(
            documentID: "document-1",
            schemaVersion: "1",
            generatedAt: "2026-09-04T10:00:00Z",
            origin: "newlyProcessed",
            candidates: [
                ExtractionCandidateDTO(
                    id: "candidate-1",
                    type: "pickupChange",
                    title: "Early pickup",
                    details: "Pickup is at 12:30.",
                    startsAt: "2026-09-10T08:30:00Z",
                    endsAt: nil,
                    isAllDay: false,
                    confidence: 0.92,
                    evidence: [
                        SourceEvidenceDTO(
                            sourceDocumentID: "document-1",
                            excerpt: "FS1 students will finish at 12:30 PM this Thursday.",
                            pageNumber: 1,
                            characterStart: 10,
                            characterEnd: 65
                        )
                    ],
                    isConflict: false,
                    isScheduleOverride: true,
                    temporal: nil
                )
            ]
        )

        let result = try DocumentDTOMapper.map(dto)

        #expect(result.documentID == DocumentID(rawValue: "document-1"))
        #expect(result.schemaVersion == "1")
        #expect(result.origin == .newlyProcessed)
        #expect(result.candidates.count == 1)
        #expect(result.candidates[0].type == .pickupChange)
        #expect(result.candidates[0].confidence.score == 0.92)
        #expect(result.candidates[0].evidence[0].pageNumber == 1)
        #expect(result.candidates[0].evidence[0].characterRange == 10..<65)
    }

    @Test
    func rejectsMaterialCandidateWithoutEvidence() {
        let dto = ExtractionResultDTO(
            documentID: "document-1",
            schemaVersion: "1",
            generatedAt: "2026-09-04T10:00:00Z",
            origin: "reused",
            candidates: [
                ExtractionCandidateDTO(
                    id: "candidate-1",
                    type: "event",
                    title: "Event",
                    details: nil,
                    startsAt: nil,
                    endsAt: nil,
                    isAllDay: true,
                    confidence: 0.8,
                    evidence: [],
                    isConflict: nil,
                    isScheduleOverride: nil,
                    temporal: nil
                )
            ]
        )

        #expect(throws: DocumentServiceError.invalidServerResponse) { _ = try DocumentDTOMapper.map(dto) }
    }

    @Test(arguments: [
        ("uploaded", DocumentProcessingStatus.uploaded), ("queued", .queued), ("processing", .processing),
        ("completed", .completed), ("failed", .failed),
    ])
    func mapsProcessingStatus(rawValue: String, expected: DocumentProcessingStatus) throws {
        let dto = DocumentProcessingStatusDTO(documentID: "document-1", status: rawValue)
        #expect(try DocumentDTOMapper.map(dto) == expected)
    }
}
