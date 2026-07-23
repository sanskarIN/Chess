import { createHash } from "node:crypto";

export function stateHash(fen: string, moves: readonly string[]): string {
  return createHash("sha256").update(`${fen}\n${moves.join(",")}`).digest("hex");
}
