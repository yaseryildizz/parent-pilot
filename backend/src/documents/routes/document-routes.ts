import type { FastifyInstance, FastifyRequest } from "fastify";
import { randomUUID } from "node:crypto";
import { ApiError } from "../../shared/api-error.js";
import { sha256Hex } from "../../shared/hash.js";
import type { DocumentScope, UploadedDocument } from "../domain/document.js";
import { toStatusResponse, toUploadResponse } from "../domain/document.js";
import type { DocumentStore } from "../domain/document-store.js";
import { UnknownDocumentError } from "../infrastructure/in-memory-document-store.js";
import type { DocumentProcessor } from "../processing/document-processor.js";

const documentScopes = new Set<DocumentScope>([
  "schoolWide",
  "yearGroup",
  "classGroup",
  "childSpecific",
  "privateParent",
  "unknown"
]);

export type DocumentRouteDependencies = {
  store: DocumentStore;
  processor: DocumentProcessor;
  maxUploadBytes: number;
  now?: () => Date;
};

export async function registerDocumentRoutes(
  app: FastifyInstance,
  dependencies: DocumentRouteDependencies
): Promise<void> {
  const now = dependencies.now ?? (() => new Date());

  app.post("/v1/documents", async (request, reply) => {
    if (!request.isMultipart()) {
      throw new ApiError({
        statusCode: 400,
        code: "invalid_multipart_request",
        message: "Upload must use multipart/form-data.",
        fieldIssues: [{ field: "Content-Type", message: "Expected multipart/form-data." }]
      });
    }

    const upload = await readUpload(request, dependencies.maxUploadBytes);
    const document: UploadedDocument = {
      id: `document-${randomUUID()}`,
      originalFilename: upload.filename,
      scope: upload.scope,
      context: upload.context,
      status: "uploaded",
      uploadedAt: now().toISOString(),
      file: {
        bytes: upload.bytes,
        mimeType: "application/pdf",
        sizeBytes: upload.bytes.byteLength,
        fileHash: sha256Hex(upload.bytes)
      }
    };

    await dependencies.store.create(document);
    dependencies.processor.start(document.id);
    return reply.code(202).send(toUploadResponse({ ...document, status: "queued" }));
  });

  app.get("/v1/documents/:id/status", async (request) => {
    const { id } = request.params as { id: string };
    const document = await findDocument(dependencies.store, id);
    return toStatusResponse(document);
  });

  app.get("/v1/documents/:id/extraction", async (request) => {
    const { id } = request.params as { id: string };
    const document = await findDocument(dependencies.store, id);

    if (document.status === "failed") {
      throw new ApiError({
        statusCode: 500,
        code: errorCodeForFailure(document.failureCode),
        message: "Document processing failed.",
        retryable: true
      });
    }

    if (document.status !== "completed" || !document.extractionResult) {
      throw new ApiError({
        statusCode: 409,
        code: "extraction_not_ready",
        message: "Extraction is not available until document processing is complete.",
        retryable: true
      });
    }

    return document.extractionResult;
  });
}

function errorCodeForFailure(failureCode: UploadedDocument["failureCode"]): string {
  switch (failureCode) {
    case "invalidPdf":
      return "invalid_pdf";
    case "noExtractableText":
      return "no_extractable_text";
    case "ocrRequired":
      return "ocr_required";
    case "pdfExtractionFailed":
      return "pdf_extraction_failed";
    case "aiProviderUnavailable":
      return "ai_provider_unavailable";
    case "aiRateLimited":
      return "ai_rate_limited";
    case "aiInvalidResponse":
      return "ai_invalid_response";
    case "semanticValidationFailed":
      return "semantic_validation_failed";
    case "processingFailed":
    case undefined:
      return "processing_failed";
  }
}

async function readUpload(
  request: FastifyRequest,
  maxUploadBytes: number
): Promise<{
  filename: string;
  bytes: Buffer;
  scope: DocumentScope;
  context: { schoolID?: string; childID?: string; classID?: string };
}> {
  let filename: string | undefined;
  let bytes: Buffer | undefined;
  let fileSeen = false;
  const fields: Record<string, string> = {};

  try {
    for await (const part of request.parts({ limits: { fileSize: maxUploadBytes, files: 1 } })) {
      if (part.type === "file") {
        if (part.fieldname !== "file") {
          await part.file.resume();
          continue;
        }

        fileSeen = true;
        validateFileMetadata(part.filename, part.mimetype);
        filename = part.filename;

        let sizeBytes = 0;
        const chunks: Buffer[] = [];
        for await (const chunk of part.file) {
          const buffer = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk);
          sizeBytes += buffer.byteLength;
          if (sizeBytes > maxUploadBytes) {
            throw new ApiError({
              statusCode: 413,
              code: "payload_too_large",
              message: "PDF upload exceeds the configured maximum size.",
              fieldIssues: [{ field: "file", message: `Maximum upload size is ${maxUploadBytes} bytes.` }]
            });
          }
          chunks.push(buffer);
        }
        bytes = Buffer.concat(chunks);
      } else if (typeof part.value === "string") {
        fields[part.fieldname] = part.value;
      }
    }
  } catch (error) {
    if (error instanceof ApiError) throw error;
    if (isMultipartLimitError(error)) {
      throw new ApiError({
        statusCode: 413,
        code: "payload_too_large",
        message: "PDF upload exceeds the configured maximum size.",
        fieldIssues: [{ field: "file", message: `Maximum upload size is ${maxUploadBytes} bytes.` }]
      });
    }
    throw new ApiError({
      statusCode: 400,
      code: "invalid_multipart_request",
      message: "Multipart upload could not be read."
    });
  }

  if (!fileSeen || !filename || !bytes) {
    throw new ApiError({
      statusCode: 400,
      code: "missing_pdf",
      message: "A PDF file is required.",
      fieldIssues: [{ field: "file", message: "Attach a PDF using the multipart field named file." }]
    });
  }

  const scope = parseScope(fields.scope);
  return {
    filename,
    bytes,
    scope,
    context: compactContext({
      schoolID: fields.schoolID,
      childID: fields.childID,
      classID: fields.classID
    })
  };
}

function validateFileMetadata(filename: string | undefined, mimetype: string): void {
  if (!filename || filename.trim().length === 0 || filename.includes("/") || filename.includes("\\")) {
    throw new ApiError({
      statusCode: 400,
      code: "invalid_filename",
      message: "PDF filename is invalid.",
      fieldIssues: [{ field: "file", message: "Use a non-empty filename without path separators." }]
    });
  }

  if (mimetype !== "application/pdf") {
    throw new ApiError({
      statusCode: 415,
      code: "unsupported_media_type",
      message: "Only application/pdf uploads are supported.",
      fieldIssues: [{ field: "file", message: "Attach a PDF with media type application/pdf." }]
    });
  }
}

function parseScope(value: string | undefined): DocumentScope {
  if (!value) return "unknown";
  if (documentScopes.has(value as DocumentScope)) return value as DocumentScope;
  throw new ApiError({
    statusCode: 400,
    code: "invalid_scope",
    message: "Document scope is invalid.",
    fieldIssues: [{ field: "scope", message: "Use a supported ParentPilot document scope." }]
  });
}

function compactContext(context: {
  schoolID?: string | undefined;
  childID?: string | undefined;
  classID?: string | undefined;
}): { schoolID?: string; childID?: string; classID?: string } {
  return Object.fromEntries(
    Object.entries(context)
      .map(([key, value]) => [key, value?.trim()])
      .filter((entry): entry is [string, string] => typeof entry[1] === "string" && entry[1].length > 0)
  );
}

async function findDocument(store: DocumentStore, id: string): Promise<UploadedDocument> {
  try {
    const document = await store.findById(id);
    if (!document) throw new UnknownDocumentError(id);
    return document;
  } catch (error) {
    if (error instanceof UnknownDocumentError) {
      throw new ApiError({
        statusCode: 404,
        code: "unknown_document",
        message: "Document was not found."
      });
    }
    throw error;
  }
}

function isMultipartLimitError(error: unknown): boolean {
  return (
    typeof error === "object" &&
    error !== null &&
    "code" in error &&
    typeof (error as { code?: unknown }).code === "string" &&
    (error as { code: string }).code.includes("FST_REQ_FILE_TOO_LARGE")
  );
}
