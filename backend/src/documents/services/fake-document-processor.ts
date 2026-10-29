import type { DocumentStore } from "../domain/document-store.js";
import type { DocumentProcessor } from "../processing/document-processor.js";
import { makeFakeExtractionResult } from "./fake-extraction-fixture.js";
import type { Scheduler } from "./scheduler.js";

export type FakeDocumentProcessorOptions = {
  store: DocumentStore;
  scheduler: Scheduler;
  transitionDelayMs: number;
  now?: () => Date;
  shouldFail?: (documentID: string) => boolean;
};

export class FakeDocumentProcessor implements DocumentProcessor {
  private readonly store: DocumentStore;
  private readonly scheduler: Scheduler;
  private readonly transitionDelayMs: number;
  private readonly now: () => Date;
  private readonly shouldFail: (documentID: string) => boolean;
  private readonly inFlight = new Set<Promise<void>>();

  constructor(options: FakeDocumentProcessorOptions) {
    this.store = options.store;
    this.scheduler = options.scheduler;
    this.transitionDelayMs = options.transitionDelayMs;
    this.now = options.now ?? (() => new Date());
    this.shouldFail = options.shouldFail ?? (() => false);
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
    try {
      await this.store.updateStatus(documentID, "queued");
      await this.scheduler.wait(this.transitionDelayMs);
      await this.store.updateStatus(documentID, "processing");
      await this.scheduler.wait(this.transitionDelayMs);

      if (this.shouldFail(documentID)) {
        await this.store.updateStatus(documentID, "failed", {
          code: "processingFailed",
          reason: "Injected fake processor failure."
        });
        return;
      }

      await this.store.complete(documentID, makeFakeExtractionResult(documentID, this.now().toISOString()));
    } catch {
      await this.store.updateStatus(documentID, "failed", {
        code: "processingFailed",
        reason: "Fake processor failed."
      });
    }
  }
}
