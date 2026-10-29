import type { AIExtractionClient } from "../ai/ai-extraction-types.js";
import { validateAndMapExtraction } from "../ai/extraction-validator.js";
import type { DocumentStore } from "../domain/document-store.js";
import type { PDFTextExtractor } from "../pdf/pdf-text-extractor.js";
import { normalizeExtractedDocumentText } from "../pdf/text-normalizer.js";
import { sha256Hex } from "../../shared/hash.js";
import { EXTRACTION_ENGINE_VERSION, EXTRACTION_SCHEMA_VERSION, PROMPT_VERSION } from "./versions.js";
import { ProcessingError, type DocumentProcessor } from "./document-processor.js";

export type OpenAIDocumentProcessorOptions = {
  store: DocumentStore;
  pdfTextExtractor: PDFTextExtractor;
  aiExtractionClient: AIExtractionClient;
  now?: () => Date;
};

export class OpenAIDocumentProcessor implements DocumentProcessor {
  private readonly store: DocumentStore;
  private readonly pdfTextExtractor: PDFTextExtractor;
  private readonly aiExtractionClient: AIExtractionClient;
  private readonly now: () => Date;
  private readonly inFlight = new Set<Promise<void>>();

  constructor(options: OpenAIDocumentProcessorOptions) {
    this.store = options.store;
    this.pdfTextExtractor = options.pdfTextExtractor;
    this.aiExtractionClient = options.aiExtractionClient;
    this.now = options.now ?? (() => new Date());
  }

  start(documentID: string): void {
    const task = this.run(documentID);
    this.inFlight.add(task);
    task.finally(() => this.inFlight.delete(task)).catch(() => undefined);
  }

  async drain(): Promise<void> {
    await Promise.allSettled(Array.from(this.inFlight));
  }

  private async run(documentID: string): Promise<void> {
    const startedAt = Date.now();
    try {
      await this.store.updateStatus(documentID, "queued");
      const document = await this.store.findById(documentID);
      if (!document) {
        throw new ProcessingError("processingFailed", "Document disappeared before processing.");
      }

      await this.store.updateStatus(documentID, "processing");
      const extractedText = await this.pdfTextExtractor.extract(document.file.bytes);
      const normalizedText = normalizeExtractedDocumentText(extractedText);
      const contentHash = sha256Hex(normalizedText.fullText);

      const aiResponse = await this.aiExtractionClient.extract({
        documentID,
        originalFilename: document.originalFilename,
        source: "pdfUpload",
        scope: document.scope,
        context: document.context,
        normalizedText,
        uploadedAt: document.uploadedAt
      });

      const validated = validateAndMapExtraction({
        documentID,
        generatedAt: this.now().toISOString(),
        sourceText: normalizedText,
        extraction: aiResponse.output
      });

      await this.store.complete(documentID, validated.result, {
        contentHash,
        extractionSchemaVersion: EXTRACTION_SCHEMA_VERSION,
        promptVersion: PROMPT_VERSION,
        extractionEngineVersion: EXTRACTION_ENGINE_VERSION,
        modelName: aiResponse.modelName,
        ...(aiResponse.usage.inputTokens !== undefined ? { inputTokens: aiResponse.usage.inputTokens } : {}),
        ...(aiResponse.usage.outputTokens !== undefined ? { outputTokens: aiResponse.usage.outputTokens } : {}),
        ...(aiResponse.usage.totalTokens !== undefined ? { totalTokens: aiResponse.usage.totalTokens } : {}),
        validCandidateCount: validated.result.candidates.length,
        processingDurationMs: Date.now() - startedAt
      });

      console.info("Document processing completed", {
        documentID,
        modelName: aiResponse.modelName,
        inputTokens: aiResponse.usage.inputTokens,
        outputTokens: aiResponse.usage.outputTokens,
        totalTokens: aiResponse.usage.totalTokens,
        validCandidateCount: validated.result.candidates.length,
        rejectedCandidateCount: validated.rejectedCandidateCount,
        processingDurationMs: Date.now() - startedAt
      });
    } catch (error) {
      const failure = normalizeProcessingError(error);
      await this.store.updateStatus(documentID, "failed", {
        code: failure.code,
        reason: failure.message
      });
      console.warn("Document processing failed", {
        documentID,
        failureCode: failure.code,
        processingDurationMs: Date.now() - startedAt
      });
    }
  }
}

function normalizeProcessingError(error: unknown): ProcessingError {
  if (error instanceof ProcessingError) return error;
  return new ProcessingError("processingFailed", "Document processing failed.", { cause: error });
}
