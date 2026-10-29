import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { describe, it } from "node:test";
import { buildApp } from "../src/app/build-app.js";
import type { AIExtractionClient, AIExtractionRequest, AIExtractionResponse } from "../src/documents/ai/ai-extraction-types.js";

const config = {
  maxUploadBytes: 1024 * 1024,
  fakeProcessingDelayMs: 1,
  documentProcessor: "openai" as const,
  openAIModel: "gpt-test"
};

describe("real document processing pipeline", () => {
  it("processes a synthetic PDF through real extraction, stub AI, validation, and the extraction endpoint", async () => {
    const app = buildApp({
      config,
      now: () => new Date("2026-09-15T08:00:00.000Z"),
      aiExtractionClient: new StubAIExtractionClient()
    });

    const pdf = await readFile("tests/fixtures/text-school-notice.pdf");
    const upload = await app.inject({
      method: "POST",
      url: "/v1/documents",
      headers: { "content-type": "multipart/form-data; boundary=test-boundary" },
      payload: multipartBody("test-boundary", pdf)
    });

    assert.equal(upload.statusCode, 202);
    const id = upload.json().id;
    await eventually(async () => {
      const response = await app.inject({ method: "GET", url: `/v1/documents/${id}/status` });
      assert.equal(response.json().status, "completed");
    });

    const extraction = await app.inject({ method: "GET", url: `/v1/documents/${id}/extraction` });
    assert.equal(extraction.statusCode, 200);
    const body = extraction.json();
    assert.equal(body.documentID, id);
    assert.equal(body.schemaVersion, "1");
    assert.equal(body.origin, "newlyProcessed");
    assert.equal(body.candidates.length, 3);
    assert.deepEqual(
      body.candidates.map((candidate: { type: string }) => candidate.type),
      ["activity", "task", "pickupChange"]
    );
    assert.equal(body.candidates[2].isScheduleOverride, true);
    assert.equal(body.candidates[2].evidence[0].pageNumber, 2);

    await app.close();
  });
});

class StubAIExtractionClient implements AIExtractionClient {
  async extract(request: AIExtractionRequest): Promise<AIExtractionResponse> {
    assert.match(request.normalizedText.fullText, /PE Day/);
    assert.match(request.normalizedText.fullText, /12:30 PM/);
    return {
      modelName: "stub-model",
      usage: { inputTokens: 100, outputTokens: 50, totalTokens: 150 },
      output: {
        candidates: [
          {
            localKey: "pe-day",
            type: "activity",
            title: "PE Day",
            details: "Wear PE kit and trainers.",
            startsAt: null,
            endsAt: null,
            isAllDay: true,
            confidence: 0.86,
            evidence: [{ excerpt: "Monday is PE Day. Children should wear PE kit and trainers.", pageNumber: 1 }],
            isConflict: false,
            isScheduleOverride: false,
            temporal: {
              date: "2026-09-21",
              startTime: null,
              endTime: null,
              timeZoneIdentifier: null,
              recurrenceWeekdays: null,
              recurrenceEndDate: null
            }
          },
          {
            localKey: "library-book",
            type: "task",
            title: "Bring library book",
            details: null,
            startsAt: null,
            endsAt: null,
            isAllDay: true,
            confidence: 0.82,
            evidence: [{ excerpt: "Please bring your library book on Wednesday.", pageNumber: 1 }],
            isConflict: false,
            isScheduleOverride: false,
            temporal: {
              date: "2026-09-23",
              startTime: null,
              endTime: null,
              timeZoneIdentifier: null,
              recurrenceWeekdays: null,
              recurrenceEndDate: null
            }
          },
          {
            localKey: "pickup-1230",
            type: "pickupChange",
            title: "Pickup change at 12:30",
            details: "Pickup is earlier due to staff training.",
            startsAt: null,
            endsAt: null,
            isAllDay: false,
            confidence: 0.94,
            evidence: [{ excerpt: "Thursday pickup will be at 12:30 PM due to staff training.", pageNumber: 2 }],
            isConflict: true,
            isScheduleOverride: true,
            temporal: {
              date: "2026-09-24",
              startTime: "12:30",
              endTime: null,
              timeZoneIdentifier: null,
              recurrenceWeekdays: null,
              recurrenceEndDate: null
            }
          },
          {
            localKey: "bad-evidence",
            type: "event",
            title: "Unsupported item",
            details: null,
            startsAt: null,
            endsAt: null,
            isAllDay: true,
            confidence: 0.7,
            evidence: [{ excerpt: "This excerpt does not appear.", pageNumber: 1 }],
            isConflict: false,
            isScheduleOverride: false,
            temporal: null
          }
        ]
      }
    };
  }
}

function multipartBody(boundary: string, pdf: Buffer): Buffer {
  return Buffer.concat([
    Buffer.from(`--${boundary}\r\nContent-Disposition: form-data; name="scope"\r\n\r\nschoolWide\r\n`),
    Buffer.from(`--${boundary}\r\nContent-Disposition: form-data; name="file"; filename="notice.pdf"\r\n`),
    Buffer.from("Content-Type: application/pdf\r\n\r\n"),
    pdf,
    Buffer.from(`\r\n--${boundary}--\r\n`)
  ]);
}

async function eventually(assertion: () => Promise<void>): Promise<void> {
  let lastError: unknown;
  for (let index = 0; index < 20; index += 1) {
    try {
      await assertion();
      return;
    } catch (error) {
      lastError = error;
      await new Promise((resolve) => setTimeout(resolve, 10));
    }
  }
  throw lastError;
}
