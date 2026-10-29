import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { describe, it } from "node:test";
import { PDFJSTextExtractor } from "../src/documents/pdf/pdf-text-extractor.js";
import { normalizeExtractedDocumentText } from "../src/documents/pdf/text-normalizer.js";
import { ProcessingError } from "../src/documents/processing/document-processor.js";

describe("PDF text extraction", () => {
  it("extracts page-aware text from a text-based PDF", async () => {
    const bytes = await readFile("tests/fixtures/text-school-notice.pdf");
    const extracted = await new PDFJSTextExtractor().extract(bytes);

    assert.equal(extracted.pages.length, 2);
    assert.equal(extracted.pages[0]?.pageNumber, 1);
    assert.match(extracted.pages[0]?.text ?? "", /PE Day/);
    assert.match(extracted.pages[1]?.text ?? "", /12:30 PM/);
  });

  it("normalizes text while preserving page boundaries", async () => {
    const bytes = await readFile("tests/fixtures/text-school-notice.pdf");
    const extracted = await new PDFJSTextExtractor().extract(bytes);
    const normalized = normalizeExtractedDocumentText(extracted);

    assert.match(normalized.fullText, /\[\[page 1\]\]/);
    assert.match(normalized.fullText, /\[\[page 2\]\]/);
    assert.equal(normalized.pages[0]?.text.includes("  "), false);
  });

  it("raises a typed failure for PDFs with no extractable text", async () => {
    const bytes = await readFile("tests/fixtures/no-text.pdf");

    await assert.rejects(
      () => new PDFJSTextExtractor().extract(bytes),
      (error) => error instanceof ProcessingError && error.code === "noExtractableText"
    );
  });
});
