export interface RelayConfig {
  host: string;
  port: number;
  roomTtlMs: number;
  reconnectGraceMs: number;
  rateLimitWindowMs: number;
  rateLimitMessages: number;
  allowedOrigins: ReadonlySet<string>;
}

export function loadConfig(
  environment: NodeJS.ProcessEnv = process.env,
): RelayConfig {
  return {
    host: environment.HOST?.trim() || "0.0.0.0",
    port: integer(environment.PORT, 8080, 0, 65_535),
    roomTtlMs: integer(environment.ROOM_TTL_MS, 30 * 60_000, 60_000),
    reconnectGraceMs: integer(
      environment.RECONNECT_GRACE_MS,
      30_000,
      1_000,
    ),
    rateLimitWindowMs: integer(
      environment.RATE_LIMIT_WINDOW_MS,
      10_000,
      1_000,
    ),
    rateLimitMessages: integer(
      environment.RATE_LIMIT_MESSAGES,
      40,
      2,
      1_000,
    ),
    allowedOrigins: new Set(
      (environment.ALLOWED_ORIGINS ?? "")
        .split(",")
        .map((value) => value.trim())
        .filter((value) => value.length > 0),
    ),
  };
}

function integer(
  raw: string | undefined,
  fallback: number,
  minimum: number,
  maximum = Number.MAX_SAFE_INTEGER,
): number {
  if (raw === undefined || raw.trim().length === 0) {
    return fallback;
  }
  const value = Number(raw);
  if (!Number.isSafeInteger(value) || value < minimum || value > maximum) {
    throw new Error(
      `Invalid numeric environment setting; expected ${minimum}..${maximum}.`,
    );
  }
  return value;
}
