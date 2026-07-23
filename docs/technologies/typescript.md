# TypeScript

The relay uses strict TypeScript with unchecked-index, exact optional-property,
unused-code, case-consistency, and fallthrough checks enabled. Runtime JSON is
still untrusted, so `protocol.ts` performs manual bounds and shape validation
before any value reaches the typed room manager.

Compilation targets modern Node ESM. Tests compile through the same project
configuration as production source.
