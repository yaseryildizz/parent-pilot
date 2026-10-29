import type {
  DocumentProcessingStatus,
  ExtractionResultDTO,
  ProcessingFailureCode,
  ProcessingMetadata,
  UploadedDocument
} from "../domain/document.js";
import type { DocumentStore } from "../domain/document-store.js";

export class UnknownDocumentError extends Error {
  constructor(id: string) {
    super(`Unknown document: ${id}`);
  }
}

export class InMemoryDocumentStore implements DocumentStore {
  private readonly documents = new Map<string, UploadedDocument>();
  private tail: Promise<void> = Promise.resolve();

  async create(document: UploadedDocument): Promise<UploadedDocument> {
    await this.withLock(() => {
      this.documents.set(document.id, copyDocument(document));
    });
    return copyDocument(document);
  }

  async findById(id: string): Promise<UploadedDocument | undefined> {
    await this.tail;
    const document = this.documents.get(id);
    return document ? copyDocument(document) : undefined;
  }

  async updateStatus(
    id: string,
    status: DocumentProcessingStatus,
    failure?: { code: ProcessingFailureCode; reason: string }
  ): Promise<UploadedDocument> {
    let updated: UploadedDocument | undefined;
    await this.withLock(() => {
      const current = this.documents.get(id);
      if (!current) throw new UnknownDocumentError(id);
      updated = { ...current, status };
      if (failure) {
        updated.failureCode = failure.code;
        updated.failureReason = failure.reason;
      } else {
        delete updated.failureCode;
        delete updated.failureReason;
      }
      this.documents.set(id, copyDocument(updated));
    });
    if (!updated) throw new UnknownDocumentError(id);
    return copyDocument(updated);
  }

  async complete(
    id: string,
    extractionResult: ExtractionResultDTO,
    processingMetadata?: ProcessingMetadata
  ): Promise<UploadedDocument> {
    let updated: UploadedDocument | undefined;
    await this.withLock(() => {
      const current = this.documents.get(id);
      if (!current) throw new UnknownDocumentError(id);
      updated = { ...current, status: "completed", extractionResult };
      if (processingMetadata) updated.processingMetadata = { ...processingMetadata };
      delete updated.failureReason;
      delete updated.failureCode;
      this.documents.set(id, copyDocument(updated));
    });
    if (!updated) throw new UnknownDocumentError(id);
    return copyDocument(updated);
  }

  private async withLock(operation: () => void): Promise<void> {
    const next = this.tail.then(operation, operation);
    this.tail = next.catch(() => undefined);
    await next;
  }
}

function copyDocument(document: UploadedDocument): UploadedDocument {
  const copy: UploadedDocument = {
    ...document,
    context: { ...document.context },
    file: {
      ...document.file,
      bytes: Buffer.from(document.file.bytes)
    }
  };
  if (document.processingMetadata) copy.processingMetadata = { ...document.processingMetadata };
  if (document.extractionResult) {
    copy.extractionResult = {
      ...document.extractionResult,
      candidates: document.extractionResult.candidates.map((candidate) => ({
        ...candidate,
        evidence: candidate.evidence.map((evidence) => ({ ...evidence })),
        ...(candidate.temporal ? { temporal: { ...candidate.temporal } } : {})
      }))
    };
  }
  return copy;
}
