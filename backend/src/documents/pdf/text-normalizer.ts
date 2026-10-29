import type { ExtractedDocumentText } from "./extracted-document-text.js";

export type NormalizedDocumentText = {
  pages: Array<{
    pageNumber: number;
    text: string;
  }>;
  fullText: string;
};

export function normalizeExtractedDocumentText(document: ExtractedDocumentText): NormalizedDocumentText {
  const pages = document.pages.map((page) => ({
    pageNumber: page.pageNumber,
    text: normalizePageText(page.text)
  }));
  return {
    pages,
    fullText: pages.map((page) => `[[page ${page.pageNumber}]]\n${page.text}`).join("\n\n")
  };
}

export function normalizeForEvidence(value: string): string {
  return value
    .normalize("NFKC")
    .replace(/\r\n?/g, "\n")
    .replace(/[ \t\f\v]+/g, " ")
    .replace(/\s*\n\s*/g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim()
    .toLowerCase();
}

function normalizePageText(value: string): string {
  return value
    .normalize("NFKC")
    .replace(/\r\n?/g, "\n")
    .replace(/[ \t\f\v]+/g, " ")
    .replace(/\s+\n/g, "\n")
    .replace(/\n\s+/g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}
