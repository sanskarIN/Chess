export const PROTOCOL_VERSION = 1 as const;

export type Color = "white" | "black";
export type SideChoice = Color | "random";

interface BaseClientMessage {
  protocolVersion: number;
  type: string;
  requestId: string;
}

export interface CreateRoomMessage extends BaseClientMessage {
  type: "create_room";
  playerName: string;
  preferredSide: SideChoice;
  codeLength: 4 | 6;
}

export interface JoinRoomMessage extends BaseClientMessage {
  type: "join_room";
  playerName: string;
  teamCode: string;
}

export interface ReadyMessage extends BaseClientMessage {
  type: "ready";
  teamCode: string;
  reconnectToken: string;
}

export interface MoveMessage extends BaseClientMessage {
  type: "move";
  teamCode: string;
  reconnectToken: string;
  ply: number;
  uci: string;
  previousStateHash: string;
}

export interface ReconnectMessage extends BaseClientMessage {
  type: "reconnect";
  teamCode: string;
  reconnectToken: string;
  lastStateHash: string;
}

export interface PingMessage extends BaseClientMessage {
  type: "ping";
}

export type ClientMessage =
  | CreateRoomMessage
  | JoinRoomMessage
  | ReadyMessage
  | MoveMessage
  | ReconnectMessage
  | PingMessage;

export type ServerMessage = Readonly<Record<string, unknown>> & {
  protocolVersion: typeof PROTOCOL_VERSION;
  type: string;
  requestId: string;
};

export class ProtocolError extends Error {
  public constructor(
    public readonly code: string,
    message: string,
    public readonly requestId = "unknown",
  ) {
    super(message);
    this.name = "ProtocolError";
  }
}

export function serverMessage(
  type: string,
  requestId: string,
  fields: Readonly<Record<string, unknown>> = {},
): ServerMessage {
  return {
    protocolVersion: PROTOCOL_VERSION,
    type,
    requestId,
    ...fields,
  };
}

export function parseClientMessage(raw: string): ClientMessage {
  let decoded: unknown;
  try {
    decoded = JSON.parse(raw);
  } catch {
    throw new ProtocolError("invalid_message", "Message must be valid JSON.");
  }
  const value = object(decoded);
  const requestId = string(value, "requestId", 1, 96);
  if (value.protocolVersion !== PROTOCOL_VERSION) {
    throw new ProtocolError(
      "protocol_mismatch",
      `Protocol version ${PROTOCOL_VERSION} is required.`,
      requestId,
    );
  }
  const type = string(value, "type", 1, 40);
  const base = {
    protocolVersion: PROTOCOL_VERSION,
    type,
    requestId,
  };
  switch (type) {
    case "create_room": {
      const preferredSide = string(value, "preferredSide", 1, 8);
      if (!["white", "black", "random"].includes(preferredSide)) {
        throw new ProtocolError(
          "invalid_message",
          "preferredSide must be white, black, or random.",
          requestId,
        );
      }
      const codeLength = integer(value, "codeLength");
      if (codeLength !== 4 && codeLength !== 6) {
        throw new ProtocolError(
          "invalid_message",
          "codeLength must be 4 or 6.",
          requestId,
        );
      }
      return {
        ...base,
        type,
        playerName: playerName(value, requestId),
        preferredSide: preferredSide as SideChoice,
        codeLength,
      };
    }
    case "join_room":
      return {
        ...base,
        type,
        playerName: playerName(value, requestId),
        teamCode: teamCode(value, requestId),
      };
    case "ready":
      return {
        ...base,
        type,
        teamCode: teamCode(value, requestId),
        reconnectToken: token(value, requestId),
      };
    case "move": {
      const uci = string(value, "uci", 4, 5);
      if (!/^[a-h][1-8][a-h][1-8][qrbn]?$/.test(uci)) {
        throw new ProtocolError(
          "invalid_message",
          "uci must be a coordinate chess move.",
          requestId,
        );
      }
      const previousStateHash = string(value, "previousStateHash", 64, 64);
      if (!/^[0-9a-f]{64}$/.test(previousStateHash)) {
        throw new ProtocolError(
          "invalid_message",
          "previousStateHash must be SHA-256.",
          requestId,
        );
      }
      const ply = integer(value, "ply");
      if (ply < 1) {
        throw new ProtocolError(
          "invalid_message",
          "ply must be positive.",
          requestId,
        );
      }
      return {
        ...base,
        type,
        teamCode: teamCode(value, requestId),
        reconnectToken: token(value, requestId),
        ply,
        uci,
        previousStateHash,
      };
    }
    case "reconnect": {
      const lastStateHash = string(value, "lastStateHash", 64, 64);
      if (!/^[0-9a-f]{64}$/.test(lastStateHash)) {
        throw new ProtocolError(
          "invalid_message",
          "lastStateHash must be SHA-256.",
          requestId,
        );
      }
      return {
        ...base,
        type,
        teamCode: teamCode(value, requestId),
        reconnectToken: token(value, requestId),
        lastStateHash,
      };
    }
    case "ping":
      return { ...base, type };
    default:
      throw new ProtocolError(
        "invalid_message",
        "Unknown message type.",
        requestId,
      );
  }
}

function object(value: unknown): Record<string, unknown> {
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    throw new ProtocolError("invalid_message", "Message must be an object.");
  }
  return value as Record<string, unknown>;
}

function string(
  value: Record<string, unknown>,
  key: string,
  minimum: number,
  maximum: number,
): string {
  const field = value[key];
  if (
    typeof field !== "string" ||
    field.length < minimum ||
    field.length > maximum
  ) {
    throw new ProtocolError(
      "invalid_message",
      `${key} has an invalid length.`,
      typeof value.requestId === "string" ? value.requestId : "unknown",
    );
  }
  return field;
}

function integer(value: Record<string, unknown>, key: string): number {
  const field = value[key];
  if (typeof field !== "number" || !Number.isSafeInteger(field)) {
    throw new ProtocolError(
      "invalid_message",
      `${key} must be an integer.`,
      typeof value.requestId === "string" ? value.requestId : "unknown",
    );
  }
  return field;
}

function playerName(
  value: Record<string, unknown>,
  requestId: string,
): string {
  const name = string(value, "playerName", 1, 40).trim();
  if (name.length === 0 || /[\u0000-\u001f\u007f]/.test(name)) {
    throw new ProtocolError(
      "invalid_message",
      "playerName contains unsupported characters.",
      requestId,
    );
  }
  return name;
}

function teamCode(
  value: Record<string, unknown>,
  requestId: string,
): string {
  const code = string(value, "teamCode", 4, 6);
  if (!/^(?:[0-9]{4}|[0-9]{6})$/.test(code)) {
    throw new ProtocolError(
      "invalid_code",
      "Team code must contain four or six digits.",
      requestId,
    );
  }
  return code;
}

function token(value: Record<string, unknown>, requestId: string): string {
  const reconnectToken = string(value, "reconnectToken", 64, 64);
  if (!/^[0-9a-f]{64}$/.test(reconnectToken)) {
    throw new ProtocolError(
      "invalid_message",
      "Reconnect token is invalid.",
      requestId,
    );
  }
  return reconnectToken;
}
