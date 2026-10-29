export interface Scheduler {
  wait(milliseconds: number): Promise<void>;
}

export class TimeoutScheduler implements Scheduler {
  wait(milliseconds: number): Promise<void> {
    return new Promise((resolve) => {
      setTimeout(resolve, milliseconds);
    });
  }
}
