export type BackendConfig = {
  host: string;
  port: number;
  maxUploadBytes: number;
  fakeProcessingDelayMs: number;
  documentProcessor: "fake" | "openai";
  openAIAPIKey?: string;
  openAIModel: string;
};

export function loadConfig(environment: NodeJS.ProcessEnv = process.env): BackendConfig {
  const documentProcessor = readProcessor(environment.DOCUMENT_PROCESSOR);
  const config: BackendConfig = {
    host: readString(environment.HOST, "0.0.0.0"),
    port: readInteger(environment.PORT, 8080),
    maxUploadBytes: readInteger(environment.MAX_UPLOAD_BYTES, 10 * 1024 * 1024),
    fakeProcessingDelayMs: readInteger(environment.FAKE_PROCESSING_DELAY, 250),
    documentProcessor,
    openAIModel: readString(environment.OPENAI_MODEL, "gpt-5-mini")
  };
  const apiKey = environment.OPENAI_API_KEY?.trim();
  if (apiKey) config.openAIAPIKey = apiKey;
  return config;
}

function readString(value: string | undefined, fallback: string): string {
  const trimmed = value?.trim();
  return trimmed && trimmed.length > 0 ? trimmed : fallback;
}

function readInteger(value: string | undefined, fallback: number): number {
  if (!value) return fallback;
  const parsed = Number.parseInt(value, 10);
  return Number.isSafeInteger(parsed) && parsed >= 0 ? parsed : fallback;
}

function readProcessor(value: string | undefined): BackendConfig["documentProcessor"] {
  if (value === "openai") return "openai";
  return "fake";
}
