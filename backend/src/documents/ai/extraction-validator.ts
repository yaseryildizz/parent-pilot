import type { ExtractionCandidateDTO, ExtractionResultDTO } from "../domain/document.js";
import type { NormalizedDocumentText } from "../pdf/text-normalizer.js";
import { normalizeForEvidence } from "../pdf/text-normalizer.js";
import { ProcessingError } from "../processing/document-processor.js";
import { EXTRACTION_SCHEMA_VERSION } from "../processing/versions.js";
import type { AIExtractionCandidate, AIStructuredExtraction, AITemporalInfo } from "./ai-extraction-types.js";

export type ValidatedExtraction = {
  result: ExtractionResultDTO;
  rejectedCandidateCount: number;
};

const candidateTypes = new Set([
  "event",
  "reminder",
  "task",
  "pickupChange",
  "holiday",
  "activity",
  "payment",
  "general"
]);

export function validateAndMapExtraction(options: {
  documentID: string;
  generatedAt: string;
  sourceText: NormalizedDocumentText;
  extraction: AIStructuredExtraction;
}): ValidatedExtraction {
  const candidates: ExtractionCandidateDTO[] = [];
  const localKeys = new Set<string>();
  const duplicateSignals = new Set<string>();
  let rejectedCandidateCount = 0;

  for (const candidate of options.extraction.candidates) {
    const mapped = validateCandidate(candidate, options.documentID, options.sourceText, localKeys, duplicateSignals);
    if (mapped) candidates.push(mapped);
    else rejectedCandidateCount += 1;
  }

  if (candidates.length === 0 && options.extraction.candidates.length > 0) {
    throw new ProcessingError("semanticValidationFailed", "No AI candidates passed semantic validation.");
  }

  return {
    rejectedCandidateCount,
    result: {
      documentID: options.documentID,
      schemaVersion: EXTRACTION_SCHEMA_VERSION,
      generatedAt: options.generatedAt,
      origin: "newlyProcessed",
      candidates
    }
  };
}

function validateCandidate(
  candidate: AIExtractionCandidate,
  documentID: string,
  sourceText: NormalizedDocumentText,
  localKeys: Set<string>,
  duplicateSignals: Set<string>
): ExtractionCandidateDTO | undefined {
  if (!candidate.localKey.trim() || localKeys.has(candidate.localKey)) return undefined;
  localKeys.add(candidate.localKey);
  if (!candidateTypes.has(candidate.type)) return undefined;
  const title = candidate.title.trim();
  if (!title || title.length > 160) return undefined;
  if (!Number.isFinite(candidate.confidence) || candidate.confidence < 0 || candidate.confidence > 1) return undefined;
  if (candidate.startsAt && !isISODateTime(candidate.startsAt)) return undefined;
  if (candidate.endsAt && !isISODateTime(candidate.endsAt)) return undefined;
  if (candidate.startsAt && candidate.endsAt && Date.parse(candidate.endsAt) < Date.parse(candidate.startsAt)) {
    return undefined;
  }
  if (candidate.temporal && !isValidTemporal(candidate.temporal)) return undefined;
  if (candidate.temporal?.startTime && candidate.temporal.endTime && candidate.temporal.endTime < candidate.temporal.startTime) {
    return undefined;
  }

  const evidence = candidate.evidence
    .map((item) => validateEvidence(item.excerpt, item.pageNumber, documentID, sourceText))
    .filter((item) => item !== undefined);
  if (evidence.length === 0) return undefined;

  const duplicateSignal = [
    candidate.type,
    title.toLowerCase(),
    candidate.temporal?.date ?? "",
    candidate.temporal?.startTime ?? "",
    candidate.startsAt ?? ""
  ].join("|");
  if (duplicateSignals.has(duplicateSignal)) return undefined;
  duplicateSignals.add(duplicateSignal);

  return {
    id: `${documentID}-${sanitizeKey(candidate.localKey)}`,
    type: candidate.type,
    title,
    details: candidate.details?.trim() ? candidate.details.trim() : null,
    startsAt: candidate.startsAt,
    endsAt: candidate.endsAt,
    isAllDay: candidate.isAllDay,
    confidence: candidate.confidence,
    evidence,
    isConflict: candidate.isConflict,
    isScheduleOverride: candidate.isScheduleOverride,
    temporal: candidate.temporal
  };
}

function validateEvidence(
  excerpt: string,
  pageNumber: number | null,
  documentID: string,
  sourceText: NormalizedDocumentText
): ExtractionCandidateDTO["evidence"][number] | undefined {
  const trimmed = excerpt.trim();
  if (!trimmed) return undefined;
  const page = pageNumber ? sourceText.pages.find((item) => item.pageNumber === pageNumber) : undefined;
  if (!page) return undefined;

  const normalizedPageText = normalizeForEvidence(page.text);
  const normalizedExcerpt = normalizeForEvidence(trimmed);
  if (!normalizedPageText.includes(normalizedExcerpt)) return undefined;

  const exactStart = page.text.indexOf(trimmed);
  return {
    sourceDocumentID: documentID,
    excerpt: trimmed,
    pageNumber,
    characterStart: exactStart >= 0 ? exactStart : null,
    characterEnd: exactStart >= 0 ? exactStart + trimmed.length : null
  };
}

function isValidTemporal(temporal: AITemporalInfo): boolean {
  if (!isCalendarDate(temporal.date)) return false;
  if (temporal.startTime && !isLocalTime(temporal.startTime)) return false;
  if (temporal.endTime && !isLocalTime(temporal.endTime)) return false;
  if (temporal.recurrenceEndDate && !isCalendarDate(temporal.recurrenceEndDate)) return false;
  if (temporal.recurrenceWeekdays) {
    const unique = new Set(temporal.recurrenceWeekdays);
    if (unique.size !== temporal.recurrenceWeekdays.length) return false;
    if (temporal.recurrenceWeekdays.some((weekday) => weekday < 1 || weekday > 7)) return false;
  }
  return true;
}

function isCalendarDate(value: string): boolean {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
  if (!match) return false;
  const year = Number(match[1]);
  const month = Number(match[2]);
  const day = Number(match[3]);
  const date = new Date(Date.UTC(year, month - 1, day));
  return date.getUTCFullYear() === year && date.getUTCMonth() === month - 1 && date.getUTCDate() === day;
}

function isLocalTime(value: string): boolean {
  const match = /^(\d{2}):(\d{2})$/.exec(value);
  if (!match) return false;
  const hour = Number(match[1]);
  const minute = Number(match[2]);
  return hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;
}

function isISODateTime(value: string): boolean {
  return Number.isFinite(Date.parse(value));
}

function sanitizeKey(value: string): string {
  const sanitized = value
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9_-]+/g, "-")
    .replace(/^-+|-+$/g, "");
  return sanitized || "candidate";
}
