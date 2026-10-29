import { ProcessingError } from "../processing/document-processor.js";
import type {
  AIExtractionClient,
  AIExtractionRequest,
  AIExtractionResponse,
  AIStructuredExtraction,
  AIUsageMetadata
} from "./ai-extraction-types.js";
import { buildExtractionInput } from "./extraction-prompt.js";
import { parentPilotExtractionSchema } from "./extraction-schema.js";

export type OpenAIExtractionClientOptions = {
  apiKey: string;
  model: string;
  fetchFn?: typeof fetch;
};

export class OpenAIExtractionClient implements AIExtractionClient {
  private readonly apiKey: string;
  private readonly model: string;
  private readonly fetchFn: typeof fetch;

  constructor(options: OpenAIExtractionClientOptions) {
    this.apiKey = options.apiKey;
    this.model = options.model;
    this.fetchFn = options.fetchFn ?? fetch;
  }

  async extract(request: AIExtractionRequest): Promise<AIExtractionResponse> {
    const response = await this.fetchFn("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${this.apiKey}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model: this.model,
        input: buildExtractionInput(request),
        tools: [],
        text: {
          format: {
            type: "json_schema",
            name: "parentpilot_school_extraction",
            description: "School calendar and task extraction candidates for ParentPilot.",
            schema: parentPilotExtractionSchema,
            strict: true
          }
        }
      })
    });

    const body = await readJSON(response);
    if (!response.ok) {
      if (response.status === 429) {
        throw new ProcessingError("aiRateLimited", "OpenAI rate limit reached.");
      }
      if (response.status >= 500) {
        throw new ProcessingError("aiProviderUnavailable", "OpenAI provider is unavailable.");
      }
      throw new ProcessingError("aiInvalidResponse", "OpenAI provider rejected the extraction request.");
    }

    return parseOpenAIResponse(body, this.model);
  }
}

async function readJSON(response: Response): Promise<unknown> {
  try {
    return await response.json();
  } catch (error) {
    throw new ProcessingError("aiInvalidResponse", "OpenAI response was not valid JSON.", { cause: error });
  }
}

function parseOpenAIResponse(body: unknown, fallbackModel: string): AIExtractionResponse {
  if (!isRecord(body)) {
    throw new ProcessingError("aiInvalidResponse", "OpenAI response body was not an object.");
  }
  if (body.status === "incomplete" || body.status === "failed" || body.status === "cancelled") {
    throw new ProcessingError("aiInvalidResponse", "OpenAI response did not complete.");
  }

  const text = extractOutputText(body);
  const parsed = parseStructuredOutput(text);
  const usage: AIUsageMetadata = {};
  const inputTokens = readNumber(body.usage, "input_tokens");
  const outputTokens = readNumber(body.usage, "output_tokens");
  const totalTokens = readNumber(body.usage, "total_tokens");
  if (inputTokens !== undefined) usage.inputTokens = inputTokens;
  if (outputTokens !== undefined) usage.outputTokens = outputTokens;
  if (totalTokens !== undefined) usage.totalTokens = totalTokens;
  return {
    modelName: typeof body.model === "string" ? body.model : fallbackModel,
    usage,
    output: parsed
  };
}

function extractOutputText(body: Record<string, unknown>): string {
  if (typeof body.output_text === "string") return body.output_text;
  const output = body.output;
  if (!Array.isArray(output)) throw new ProcessingError("aiInvalidResponse", "OpenAI response had no output text.");
  for (const item of output) {
    if (!isRecord(item) || !Array.isArray(item.content)) continue;
    for (const content of item.content) {
      if (!isRecord(content)) continue;
      if (content.type === "refusal") {
        throw new ProcessingError("aiInvalidResponse", "OpenAI refused the extraction request.");
      }
      if (content.type === "output_text" && typeof content.text === "string") return content.text;
    }
  }
  throw new ProcessingError("aiInvalidResponse", "OpenAI response had no output text.");
}

function parseStructuredOutput(value: string): AIStructuredExtraction {
  try {
    const parsed = JSON.parse(value) as unknown;
    if (!isStructuredExtraction(parsed)) {
      throw new ProcessingError("aiInvalidResponse", "OpenAI structured output did not match expected shape.");
    }
    return parsed;
  } catch (error) {
    if (error instanceof ProcessingError) throw error;
    throw new ProcessingError("aiInvalidResponse", "OpenAI structured output was not valid JSON.", { cause: error });
  }
}

function isStructuredExtraction(value: unknown): value is AIStructuredExtraction {
  return isRecord(value) && Array.isArray(value.candidates);
}

function readNumber(parent: unknown, field: string): number | undefined {
  if (!isRecord(parent)) return undefined;
  const value = parent[field];
  return typeof value === "number" ? value : undefined;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}
