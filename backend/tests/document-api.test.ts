import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { buildApp } from "../src/app/build-app.js";
import { ManualScheduler } from "./manual-scheduler.js";

const config = {
  maxUploadBytes: 1024 * 1024,
  fakeProcessingDelayMs: 1,
  documentProcessor: "fake" as const,
  openAIModel: "gpt-test"
};

describe("ParentPilot backend API", () => {
  it("returns minimal health information", async () => {
    const app = buildApp({ config });
    const response = await app.inject({ method: "GET", url: "/health" });
    assert.equal(response.statusCode, 200);
    assert.deepEqual(response.json(), { status: "ok" });
    await app.close();
  });

  it("accepts a valid PDF upload and returns the iOS upload response contract", async () => {
    const scheduler = new ManualScheduler();
    const app = buildApp({ config, scheduler, now: fixedNow });
    const response = await uploadPDF(app, { fields: { scope: "schoolWide", schoolID: "school-1" } });

    assert.equal(response.statusCode, 202);
    const body = response.json();
    assert.match(body.id, /^document-/);
    assert.equal(body.originalFilename, "calendar.pdf");
    assert.equal(body.uploadedAt, "2026-09-08T08:00:00.000Z");
    assert.equal(body.source, "pdfUpload");
    assert.equal(body.scope, "schoolWide");
    assert.equal(body.processingStatus, "queued");
    assert.equal(body.schoolID, "school-1");
    assert.equal(body.childID, null);
    assert.equal(body.classID, null);
    scheduler.advance();
    await tick();
    scheduler.advance();
    await tick();
    await app.close();
  });

  it("rejects a missing file", async () => {
    const app = buildApp({ config });
    const response = await app.inject({
      method: "POST",
      url: "/v1/documents",
      headers: multipartHeaders("missing-file-boundary"),
      payload: multipartBody("missing-file-boundary", [{ name: "scope", value: "schoolWide" }])
    });

    assert.equal(response.statusCode, 400);
    assert.equal(response.json().error.code, "missing_pdf");
    await app.close();
  });

  it("rejects unsupported file types", async () => {
    const app = buildApp({ config });
    const response = await uploadPDF(app, {
      filename: "notes.txt",
      contentType: "text/plain",
      content: "hello"
    });

    assert.equal(response.statusCode, 415);
    assert.equal(response.json().error.code, "unsupported_media_type");
    await app.close();
  });

  it("returns 413 for uploads over the configured limit", async () => {
    const app = buildApp({ config: { ...config, maxUploadBytes: 4 } });
    const response = await uploadPDF(app, { content: "%PDF-this is too large" });

    assert.equal(response.statusCode, 413);
    assert.equal(response.json().error.code, "payload_too_large");
    await app.close();
  });

  it("reports deterministic processing status lifecycle", async () => {
    const scheduler = new ManualScheduler();
    const app = buildApp({ config, scheduler });
    const upload = await uploadPDF(app);
    const id = upload.json().id;

    assert.equal((await status(app, id)).status, "queued");
    assert.equal(scheduler.pendingCount, 1);

    scheduler.advance();
    await tick();
    assert.equal((await status(app, id)).status, "processing");

    scheduler.advance();
    await tick();
    assert.equal((await status(app, id)).status, "completed");
    await app.close();
  });

  it("returns completed extraction response matching the Swift DTO shape", async () => {
    const scheduler = new ManualScheduler();
    const app = buildApp({ config, scheduler, now: fixedNow });
    const upload = await uploadPDF(app);
    const id = upload.json().id;

    scheduler.advance();
    await tick();
    scheduler.advance();
    await tick();

    const response = await app.inject({ method: "GET", url: `/v1/documents/${id}/extraction` });
    assert.equal(response.statusCode, 200);
    const body = response.json();
    assert.equal(body.documentID, id);
    assert.equal(body.schemaVersion, "1");
    assert.equal(body.generatedAt, "2026-09-08T08:00:00.000Z");
    assert.equal(body.origin, "newlyProcessed");
    assert.equal(body.candidates.length, 3);
    assert.deepEqual(
      body.candidates.map((candidate: { type: string }) => candidate.type),
      ["activity", "task", "pickupChange"]
    );
    assert.equal(body.candidates[2].isScheduleOverride, true);
    assert.equal(body.candidates[2].temporal.startTime, "12:30");
    assert.equal(body.candidates.every((candidate: { evidence: unknown[] }) => candidate.evidence.length > 0), true);
    await app.close();
  });

  it("returns 409 when extraction is requested before completion", async () => {
    const scheduler = new ManualScheduler();
    const app = buildApp({ config, scheduler });
    const upload = await uploadPDF(app);
    const id = upload.json().id;

    const response = await app.inject({ method: "GET", url: `/v1/documents/${id}/extraction` });
    assert.equal(response.statusCode, 409);
    assert.equal(response.json().error.code, "extraction_not_ready");
    scheduler.advance();
    await tick();
    scheduler.advance();
    await tick();
    await app.close();
  });

  it("returns 404 for unknown documents", async () => {
    const app = buildApp({ config });
    const response = await app.inject({ method: "GET", url: "/v1/documents/document-missing/status" });

    assert.equal(response.statusCode, 404);
    assert.equal(response.json().error.code, "unknown_document");
    await app.close();
  });

  it("surfaces an injectable processing failure path", async () => {
    const scheduler = new ManualScheduler();
    const app = buildApp({
      config,
      scheduler,
      shouldFailProcessing: () => true
    });
    const upload = await uploadPDF(app);
    const id = upload.json().id;

    scheduler.advance();
    await tick();
    scheduler.advance();
    await tick();

    assert.equal((await status(app, id)).status, "failed");
    const extraction = await app.inject({ method: "GET", url: `/v1/documents/${id}/extraction` });
    assert.equal(extraction.statusCode, 500);
    assert.equal(extraction.json().error.code, "processing_failed");
    await app.close();
  });
});

async function uploadPDF(
  app: ReturnType<typeof buildApp>,
  options: {
    filename?: string;
    contentType?: string;
    content?: string;
    fields?: Record<string, string>;
  } = {}
) {
  const boundary = "parentpilot-test-boundary";
  return app.inject({
    method: "POST",
    url: "/v1/documents",
    headers: multipartHeaders(boundary),
    payload: multipartBody(boundary, [
      { name: "scope", value: options.fields?.scope ?? "schoolWide" },
      ...Object.entries(options.fields ?? {})
        .filter(([name]) => name !== "scope")
        .map(([name, value]) => ({ name, value })),
      {
        name: "file",
        filename: options.filename ?? "calendar.pdf",
        contentType: options.contentType ?? "application/pdf",
        value: options.content ?? "%PDF-1.7\nfixture\n%%EOF"
      }
    ])
  });
}

function multipartHeaders(boundary: string): Record<string, string> {
  return { "content-type": `multipart/form-data; boundary=${boundary}` };
}

function multipartBody(
  boundary: string,
  parts: Array<{ name: string; value: string; filename?: string; contentType?: string }>
): string {
  const lines: string[] = [];
  for (const part of parts) {
    lines.push(`--${boundary}`);
    if (part.filename) {
      lines.push(
        `Content-Disposition: form-data; name="${part.name}"; filename="${part.filename}"`,
        `Content-Type: ${part.contentType ?? "application/octet-stream"}`,
        "",
        part.value
      );
    } else {
      lines.push(`Content-Disposition: form-data; name="${part.name}"`, "", part.value);
    }
  }
  lines.push(`--${boundary}--`, "");
  return lines.join("\r\n");
}

async function status(app: ReturnType<typeof buildApp>, id: string): Promise<{ documentID: string; status: string }> {
  const response = await app.inject({ method: "GET", url: `/v1/documents/${id}/status` });
  assert.equal(response.statusCode, 200);
  return response.json();
}

function fixedNow(): Date {
  return new Date("2026-09-08T08:00:00.000Z");
}

async function tick(): Promise<void> {
  await new Promise((resolve) => setImmediate(resolve));
}
