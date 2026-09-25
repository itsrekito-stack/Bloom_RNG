# Phase 6A — Studio persistence join / leave / rejoin probe

This stage does **not** claim Roblox Studio/DataStore integration has passed. GitHub CI cannot replace a real Studio session.

## What is now automated

`src/ServerScriptService/PersistenceProbe.server.luau` runs only when `RunService:IsStudio()` is true. It never calls DataStore APIs and never mutates the player profile.

While a profile is active it computes a deterministic digest of the in-memory profile and exposes it as the player attribute `BloomPersistenceDigest`.

It prints:

- `[PersistenceProbe] JOIN user=<id> digest=<digest>` once the profile is available.
- `[PersistenceProbe] LEAVE user=<id> digest=<digest> state=<state>` when the player leaves.

## Acceptance for RoFlow: Studio persistence A

1. Enable Studio API access for the published test experience.
2. Join and wait for the JOIN line.
3. Change real progression through normal gameplay.
4. Leave normally.
5. Record the final LEAVE digest.
6. Rejoin the same published test experience.
7. The next JOIN digest must equal the previous LEAVE digest.

PASS is only valid when the digests match and no `BloomProfileError` / DataService recovery kick appears.

A mismatch means the persisted profile did not reproduce the last in-memory state and the RoFlow task must remain open.

The probe is intentionally not active in live servers.
