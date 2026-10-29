export interface DocumentProcessor {
  start(documentID: string): void;
  drain(): Promise<void>;
}

export class ProcessingError extends Error {
  readonly code:
    | "invalidPdf"
    | "noExtractableText"
    | "ocrRequired"
    | "pdfExtractionFailed"
    | "aiProviderUnavailable"
    | "aiRateLimited"
    | "aiInvalidResponse"
    | "semanticValidationFailed"
    | "processingFailed";

  constructor(
    code: ProcessingError["code"],
    message: string,
    options?: {
      cause?: unknown;
    }
  ) {
    super(message, options);
    this.code = code;
  }
}
