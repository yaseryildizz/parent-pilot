export const parentPilotExtractionSchema = {
  type: "object",
  additionalProperties: false,
  required: ["candidates"],
  properties: {
    candidates: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: [
          "localKey",
          "type",
          "title",
          "details",
          "startsAt",
          "endsAt",
          "isAllDay",
          "confidence",
          "evidence",
          "isConflict",
          "isScheduleOverride",
          "temporal"
        ],
        properties: {
          localKey: { type: "string" },
          type: {
            type: "string",
            enum: ["event", "reminder", "task", "pickupChange", "holiday", "activity", "payment", "general"]
          },
          title: { type: "string" },
          details: { type: ["string", "null"] },
          startsAt: { type: ["string", "null"] },
          endsAt: { type: ["string", "null"] },
          isAllDay: { type: "boolean" },
          confidence: { type: "number" },
          evidence: {
            type: "array",
            items: {
              type: "object",
              additionalProperties: false,
              required: ["excerpt", "pageNumber"],
              properties: {
                excerpt: { type: "string" },
                pageNumber: { type: ["integer", "null"] }
              }
            }
          },
          isConflict: { type: "boolean" },
          isScheduleOverride: { type: "boolean" },
          temporal: {
            anyOf: [
              { type: "null" },
              {
                type: "object",
                additionalProperties: false,
                required: [
                  "date",
                  "startTime",
                  "endTime",
                  "timeZoneIdentifier",
                  "recurrenceWeekdays",
                  "recurrenceEndDate"
                ],
                properties: {
                  date: { type: "string" },
                  startTime: { type: ["string", "null"] },
                  endTime: { type: ["string", "null"] },
                  timeZoneIdentifier: { type: ["string", "null"] },
                  recurrenceWeekdays: {
                    anyOf: [
                      { type: "null" },
                      {
                        type: "array",
                        items: { type: "integer" }
                      }
                    ]
                  },
                  recurrenceEndDate: { type: ["string", "null"] }
                }
              }
            ]
          }
        }
      }
    }
  }
} as const;
