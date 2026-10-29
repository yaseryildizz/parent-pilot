import type { DocumentContext, DocumentScope } from "../domain/document.js";
import type { NormalizedDocumentText } from "../pdf/text-normalizer.js";

export type AIExtractionRequest = {
  documentID: string;
  originalFilename: string;
  source: "pdfUpload";
  scope: DocumentScope;
  context: DocumentContext;
  normalizedText: NormalizedDocumentText;
  uploadedAt: string;
};

export type AIUsageMetadata = {
  inputTokens?: number;
  outputTokens?: number;
  totalTokens?: number;
};

export type AIExtractionResponse = {
  modelName: string;
  usage: AIUsageMetadata;
  output: AIStructuredExtraction;
};

export type AIStructuredExtraction = {
  candidates: AIExtractionCandidate[];
};

export type AIExtractionCandidate = {
  localKey: string;
  type: "event" | "reminder" | "task" | "pickupChange" | "holiday" | "activity" | "payment" | "general";
  title: string;
  details: string | null;
  startsAt: string | null;
  endsAt: string | null;
  isAllDay: boolean;
  confidence: number;
  evidence: AIEvidence[];
  isConflict: boolean;
  isScheduleOverride: boolean;
  temporal: AITemporalInfo | null;
};

export type AIEvidence = {
  excerpt: string;
  pageNumber: number | null;
};

export type AITemporalInfo = {
  date: string;
  startTime: string | null;
  endTime: string | null;
  timeZoneIdentifier: string | null;
  recurrenceWeekdays: number[] | null;
  recurrenceEndDate: string | null;
};

export interface AIExtractionClient {
  extract(request: AIExtractionRequest): Promise<AIExtractionResponse>;
}
