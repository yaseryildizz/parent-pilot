import type { ExtractionResultDTO } from "../domain/document.js";

export function makeFakeExtractionResult(documentID: string, generatedAt: string): ExtractionResultDTO {
  return {
    documentID,
    schemaVersion: "1",
    generatedAt,
    origin: "newlyProcessed",
    candidates: [
      {
        id: `${documentID}-candidate-pe-day`,
        type: "activity",
        title: "PE Day",
        details: "Wear PE kit and trainers.",
        startsAt: "2026-09-14T04:00:00Z",
        endsAt: null,
        isAllDay: true,
        confidence: 0.89,
        evidence: [
          {
            sourceDocumentID: documentID,
            excerpt: "Monday is PE Day. Children should wear PE kit and trainers.",
            pageNumber: 1,
            characterStart: 18,
            characterEnd: 79
          }
        ],
        isConflict: false,
        isScheduleOverride: false,
        temporal: {
          date: "2026-09-14",
          startTime: null,
          endTime: null,
          timeZoneIdentifier: "Asia/Dubai",
          recurrenceWeekdays: [2],
          recurrenceEndDate: "2026-12-14"
        }
      },
      {
        id: `${documentID}-candidate-library-book`,
        type: "task",
        title: "Bring library book",
        details: "Return the library book for the class library session.",
        startsAt: null,
        endsAt: null,
        isAllDay: true,
        confidence: 0.84,
        evidence: [
          {
            sourceDocumentID: documentID,
            excerpt: "Please bring your library book on Wednesday.",
            pageNumber: 1,
            characterStart: 92,
            characterEnd: 136
          }
        ],
        isConflict: false,
        isScheduleOverride: false,
        temporal: {
          date: "2026-09-16",
          startTime: null,
          endTime: null,
          timeZoneIdentifier: "Asia/Dubai",
          recurrenceWeekdays: null,
          recurrenceEndDate: null
        }
      },
      {
        id: `${documentID}-candidate-pickup-change`,
        type: "pickupChange",
        title: "Pickup change at 12:30",
        details: "Pickup is earlier than usual because of staff training.",
        startsAt: "2026-09-17T08:30:00Z",
        endsAt: null,
        isAllDay: false,
        confidence: 0.94,
        evidence: [
          {
            sourceDocumentID: documentID,
            excerpt: "Thursday pickup will be at 12:30 PM due to staff training.",
            pageNumber: 2,
            characterStart: 8,
            characterEnd: 69
          }
        ],
        isConflict: true,
        isScheduleOverride: true,
        temporal: {
          date: "2026-09-17",
          startTime: "12:30",
          endTime: null,
          timeZoneIdentifier: "Asia/Dubai",
          recurrenceWeekdays: null,
          recurrenceEndDate: null
        }
      }
    ]
  };
}
