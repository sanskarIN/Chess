export class SlidingWindowRateLimiter {
  private readonly timestamps: number[] = [];

  public constructor(
    private readonly limit: number,
    private readonly windowMs: number,
    private readonly now: () => number = Date.now,
  ) {}

  public allow(): boolean {
    const threshold = this.now() - this.windowMs;
    while (
      this.timestamps.length > 0 &&
      (this.timestamps[0] ?? Number.POSITIVE_INFINITY) <= threshold
    ) {
      this.timestamps.shift();
    }
    if (this.timestamps.length >= this.limit) {
      return false;
    }
    this.timestamps.push(this.now());
    return true;
  }
}
