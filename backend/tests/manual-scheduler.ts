import type { Scheduler } from "../src/documents/services/scheduler.js";

export class ManualScheduler implements Scheduler {
  private readonly resolvers: Array<() => void> = [];

  wait(_milliseconds: number): Promise<void> {
    return new Promise((resolve) => {
      this.resolvers.push(resolve);
    });
  }

  advance(): void {
    const resolve = this.resolvers.shift();
    if (!resolve) throw new Error("No scheduled transition is waiting.");
    resolve();
  }

  get pendingCount(): number {
    return this.resolvers.length;
  }
}
