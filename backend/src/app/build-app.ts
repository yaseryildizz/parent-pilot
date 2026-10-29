import multipart from "@fastify/multipart";
import Fastify, { type FastifyInstance } from "fastify";
import { randomUUID } from "node:crypto";
import type { BackendConfig } from "../config/config.js";
import type { AIExtractionClient } from "../documents/ai/ai-extraction-types.js";
import { OpenAIExtractionClient } from "../documents/ai/openai-extraction-client.js";
import { InMemoryDocumentStore } from "../documents/infrastructure/in-memory-document-store.js";
import { PDFJSTextExtractor, type PDFTextExtractor } from "../documents/pdf/pdf-text-extractor.js";
import type { DocumentProcessor } from "../documents/processing/document-processor.js";
import { OpenAIDocumentProcessor } from "../documents/processing/openai-document-processor.js";
import { registerDocumentRoutes } from "../documents/routes/document-routes.js";
import { FakeDocumentProcessor } from "../documents/services/fake-document-processor.js";
import { TimeoutScheduler, type Scheduler } from "../documents/services/scheduler.js";
import { ApiError, errorEnvelope } from "../shared/api-error.js";

export type BuildAppOptions = {
  config: Pick<
    BackendConfig,
    "maxUploadBytes" | "fakeProcessingDelayMs" | "documentProcessor" | "openAIAPIKey" | "openAIModel"
  >;
  scheduler?: Scheduler;
  now?: () => Date;
  shouldFailProcessing?: (documentID: string) => boolean;
  processor?: DocumentProcessor;
  aiExtractionClient?: AIExtractionClient;
  pdfTextExtractor?: PDFTextExtractor;
};

export function buildApp(options: BuildAppOptions): FastifyInstance {
  const app = Fastify({
    logger: false,
    genReqId: (request) => {
      const header = request.headers["x-request-id"];
      return Array.isArray(header) ? (header[0] ?? cryptoRandomID()) : (header ?? cryptoRandomID());
    },
    requestIdHeader: "x-request-id"
  });

  const store = new InMemoryDocumentStore();
  const processor = options.processor ?? makeProcessor(options, store);

  app.addHook("onRequest", async (request, reply) => {
    reply.header("x-request-id", request.id);
  });

  app.setErrorHandler((error, request, reply) => {
    const apiError = normalizeError(error);
    request.log.warn({ err: error, requestID: request.id }, "Request failed");
    reply.code(apiError.statusCode).send(errorEnvelope(apiError, request.id));
  });

  app.register(multipart, {
    limits: {
      fileSize: options.config.maxUploadBytes,
      files: 1
    }
  });

  app.get("/health", async () => ({ status: "ok" }));
  app.register(registerDocumentRoutes, {
    store,
    processor,
    maxUploadBytes: options.config.maxUploadBytes,
    ...(options.now ? { now: options.now } : {})
  });

  app.addHook("onClose", async () => {
    await processor.drain();
  });

  return app;
}

function makeProcessor(options: BuildAppOptions, store: InMemoryDocumentStore): DocumentProcessor {
  if (options.config.documentProcessor === "openai") {
    if (!options.config.openAIAPIKey && !options.aiExtractionClient) {
      throw new Error("OPENAI_API_KEY is required when DOCUMENT_PROCESSOR=openai.");
    }
    return new OpenAIDocumentProcessor({
      store,
      pdfTextExtractor: options.pdfTextExtractor ?? new PDFJSTextExtractor(),
      aiExtractionClient:
        options.aiExtractionClient ??
        new OpenAIExtractionClient({
          apiKey: options.config.openAIAPIKey ?? "",
          model: options.config.openAIModel
        }),
      ...(options.now ? { now: options.now } : {})
    });
  }

  return new FakeDocumentProcessor({
    store,
    scheduler: options.scheduler ?? new TimeoutScheduler(),
    transitionDelayMs: options.config.fakeProcessingDelayMs,
    ...(options.now ? { now: options.now } : {}),
    ...(options.shouldFailProcessing ? { shouldFail: options.shouldFailProcessing } : {})
  });
}

function normalizeError(error: unknown): ApiError {
  if (error instanceof ApiError) return error;
  if (typeof error === "object" && error !== null && "statusCode" in error && error.statusCode === 413) {
    return new ApiError({
      statusCode: 413,
      code: "payload_too_large",
      message: "PDF upload exceeds the configured maximum size."
    });
  }
  return new ApiError({
    statusCode: 500,
    code: "internal_error",
    message: "The request could not be completed.",
    retryable: true
  });
}

function cryptoRandomID(): string {
  return `request-${randomUUID()}`;
}
