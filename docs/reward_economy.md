# Local reward economy

Chess-Master's first-release economy is local and non-monetary. It has no real
money, billing SDK, advertising reward, gambling, loot box, randomized paid
reward, artificial urgency, or pay-to-win claim. A first initialization grants
50 coins and 1 hint token once. Daily challenge rewards then provide the
repeatable earning path.

## Wallet and atomic ledger

SQLite schema version 2 stores one non-negative balance for `coin` and `hint`.
Every mutation writes an append-only ledger entry containing:

- transaction ID and monotonic ledger sequence;
- transaction type and asset type;
- signed amount;
- balance before and balance after;
- source and optional related challenge ID;
- UTC timestamp and application version;
- previous and current integrity hashes.

Supported transaction types include daily and challenge rewards, achievements,
hint purchases, refunds, migrations, developer adjustments, resets, and the
one-time onboarding reward. Phase 7 actively writes challenge, hint-purchase,
and onboarding entries.

The database transaction reads the current balance, rejects any negative result,
writes the ledger row, and updates the wallet together. A uniqueness constraint
on transaction type, asset, and source makes repeated claim and purchase
requests idempotent. The reward screen can display the ledger, validate its hash
chain, and copy a structured JSON export.

The hashes detect accidental inconsistency; they are not a secret-backed
anti-tamper system. A user who controls an offline open-source build and its
database can modify or recompute local values.

## Hint pricing

An eligible computer-game hint costs either 1 earned hint token or 25 earned
coins. The player chooses the asset in a confirmation dialog. A separate local
search produces a legal candidate before the repository is asked to charge.
Search failure, cancellation, invalid output, or an unavailable balance returns
without creating a purchase entry.

There are no purchases outside an active position because a hint must correspond
to a concrete legal board state. Future premium functionality is documentation
only until billing, parental protection, tax, policy, restoration, and legal
requirements receive separate approval.
