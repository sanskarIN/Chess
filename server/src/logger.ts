export interface RelayLogger {
  info(event: string, fields?: Readonly<Record<string, unknown>>): void;
  warn(event: string, fields?: Readonly<Record<string, unknown>>): void;
  error(event: string, fields?: Readonly<Record<string, unknown>>): void;
}

const sensitiveKeys = new Set([
  "address",
  "ip",
  "name",
  "playerName",
  "roomCode",
  "teamCode",
  "token",
  "reconnectToken",
]);

export class JsonRelayLogger implements RelayLogger {
  public info(
    event: string,
    fields: Readonly<Record<string, unknown>> = {},
  ): void {
    this.write("info", event, fields);
  }

  public warn(
    event: string,
    fields: Readonly<Record<string, unknown>> = {},
  ): void {
    this.write("warning", event, fields);
  }

  public error(
    event: string,
    fields: Readonly<Record<string, unknown>> = {},
  ): void {
    this.write("error", event, fields);
  }

  private write(
    level: string,
    event: string,
    fields: Readonly<Record<string, unknown>>,
  ): void {
    const safeFields = Object.fromEntries(
      Object.entries(fields).map(([key, value]) => [
        key,
        sensitiveKeys.has(key) ? "<redacted>" : value,
      ]),
    );
    process.stdout.write(
      `${JSON.stringify({
        timestamp: new Date().toISOString(),
        level,
        event,
        ...safeFields,
      })}\n`,
    );
  }
}
