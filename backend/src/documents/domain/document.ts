export type DocumentProcessingStatus = "uploaded" | "queued" | "processing" | "completed" | "failed";

export type DocumentScope =
  | "schoolWide"
  | "yearGroup"
  | "classGroup"
  | "childSpecific"
  | "privateParent"
  | "unknown";

export type DocumentContext = {
  schoolID?: string;
  childID?: string;
  classID?: string;
};

export type ProcessingFailureCode =
  | "invalidPdf"
  | "noExtractableText"
  | "ocrRequired"
  | "pdfExtractionFailed"
  | "aiProviderUnavailable"
  | "aiRateLimited"
  | "aiInvalidResponse"
  | "semanticValidationFailed"
  | "processingFailed";

export type UploadedFile = {
  bytes: Buffer;
  mimeType: "application/pdf";
  sizeBytes: number;
  fileHash: string;
};

export type ProcessingMetadata = {
  contentHash?: string;
  extractionSchemaVersion?: string;
  promptVersion?: string;
  extractionEngineVersion?: string;
  modelName?: string;
  inputTokens?: number;
  outputTokens?: number;
  totalTokens?: number;
  validCandidateCount?: number;
  processingDurationMs?: number;
};

export type UploadedDocument = {
  id: string;
  originalFilename: string;
  scope: DocumentScope;
  context: DocumentContext;
  status: DocumentProcessingStatus;
  uploadedAt: string;
  file: UploadedFile;
  extractionResult?: ExtractionResultDTO;
  failureCode?: ProcessingFailureCode;
  failureReason?: string;
  processingMetadata?: ProcessingMetadata;
};

export type DocumentUploadResponseDTO = {
  id: string;
  originalFilename: string;
  uploadedAt: string;
  source: "pdfUpload";
  scope: DocumentScope;
  processingStatus: DocumentProcessingStatus;
  schoolID?: string | null;
  childID?: string | null;
  classID?: string | null;
};

export type DocumentProcessingStatusDTO = {
  documentID: string;
  status: DocumentProcessingStatus;
};

export type ExtractionResultDTO = {
  documentID: string;
  schemaVersion: string;
  generatedAt: string;
  origin: "newlyProcessed" | "reused";
  candidates: ExtractionCandidateDTO[];
};

export type ExtractionCandidateDTO = {
  id: string;
  type: "event" | "reminder" | "task" | "pickupChange" | "holiday" | "activity" | "payment" | "general";
  title: string;
  details?: string | null;
  startsAt?: string | null;
  endsAt?: string | null;
  isAllDay: boolean;
  confidence: number;
  evidence: SourceEvidenceDTO[];
  isConflict?: boolean | null;
  isScheduleOverride?: boolean | null;
  temporal?: ExtractedTemporalInfoDTO | null;
};

export type SourceEvidenceDTO = {
  sourceDocumentID: string;
  excerpt: string;
  pageNumber?: number | null;
  characterStart?: number | null;
  characterEnd?: number | null;
};

export type ExtractedTemporalInfoDTO = {
  date: string;
  startTime?: string | null;
  endTime?: string | null;
  timeZoneIdentifier?: string | null;
  recurrenceWeekdays?: number[] | null;
  recurrenceEndDate?: string | null;
};

export function toUploadResponse(document: UploadedDocument): DocumentUploadResponseDTO {
  return {
    id: document.id,
    originalFilename: document.originalFilename,
    uploadedAt: document.uploadedAt,
    source: "pdfUpload",
    scope: document.scope,
    processingStatus: document.status,
    schoolID: document.context.schoolID ?? null,
    childID: document.context.childID ?? null,
    classID: document.context.classID ?? null
  };
}

export function toStatusResponse(document: UploadedDocument): DocumentProcessingStatusDTO {
  return {
    documentID: document.id,
    status: document.status
  };
}
