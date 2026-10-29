import type {
  DocumentProcessingStatus,
  ExtractionResultDTO,
  ProcessingFailureCode,
  ProcessingMetadata,
  UploadedDocument
} from "./document.js";

export interface DocumentStore {
  create(document: UploadedDocument): Promise<UploadedDocument>;
  findById(id: string): Promise<UploadedDocument | undefined>;
  updateStatus(
    id: string,
    status: DocumentProcessingStatus,
    failure?: { code: ProcessingFailureCode; reason: string }
  ): Promise<UploadedDocument>;
  complete(
    id: string,
    extractionResult: ExtractionResultDTO,
    processingMetadata?: ProcessingMetadata
  ): Promise<UploadedDocument>;
}
