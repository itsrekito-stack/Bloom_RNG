# Scope

Phase 2A only: BR-001, BR-004, BR-003, BR-009. No UI layout, inventory routing, roulette, balance, snapshot or network optimization changes. `UIStateService` only gains four server-generated reason messages. Static Phase 1 statements were rechecked against source: `BloomUtil.Number` already repaired negatives for fields that called it; BR-009 concerned incomplete coverage, unknown IDs, inconsistent relationships and destructive slot sanitization, not absence of all numeric protection.

# Backup / Starting HEAD

- Repository: `itsrekito-stack/Bloom_RNG`, target `main`.
- Starting HEAD: `c4f4ed542a1273a849a8c4a72f3d33b1cafd99a6`.
- Verified checkpoint: `backup-before-phase2a-persistence` at that exact SHA.
- Read the current Phase 1 report and current DataService, DataConfig, ProfileSchema, SeasonService, PlayerService, WorkshopService, GardenPlotService, StatsService, configs, shared modules and tests. Recent history includes profile handshake, inventory integration and English server messages; unrelated work is preserved.
- Changes are grouped into persistence/caller coordination, progression/schema/tests, then this report. `main` receives the final tested commit chain in one non-forced fast-forward.

# BR-001 Implementation

`src/ServerScriptService/Services/DataService.luau` is the sole per-user persistence lifecycle owner. A record has one operation, an immutable operation snapshot, a unique operation id, a unique acquisition token, a close request and an explicit outcome. Final release removes the record **only** after a confirmed release write or an authoritative UpdateAsync callback observes that operation's marker. Failed/uncertain candidates and the live record remain in memory in a terminal diagnostic state after the bounded retry budget. They are not passed to a second writer or discarded as if saved.

The envelope retains `RecordVersion=1`, revision, session and Data, and adds `LastOperationId` for idempotent acknowledgement recovery. Each retry uses the same candidate and id. Observing the marker returns nil from the callback: confirmation does not rewrite another session's data or renew the lease. Session ownership and expiry are checked inside UpdateAsync before a write. An expired old token is never resurrected.

A normal autosave may run while gameplay mutates live memory; it does not replace that live table with its older snapshot on success. If leave arrives during autosave, the final snapshot is captured only after the autosave finishes. Any ambiguous failure pauses access through GetProfile; exhaustion kicks/fails closed and retains diagnostics. Malformed stored envelopes cannot be mistaken for a new default profile.

# BR-004 Implementation

`SeasonService:Confirm` consumes `result.Code` from `CommitProfile`, not a boolean. DataService sets Transaction before starting a yielding write. PlayerRemoving and Shutdown set CloseRequested and let the existing operation complete; they do not write the pre-turn profile. On confirmed commit, DataService replaces live data with the committed candidate and hands closing to a final release using that candidate. On unknown outcome, no normal save can run.

The separate `PlayerService.Busy` gate was removed: it had no other producer and could be cleared independently of persistence. All callers use DataService:GetProfile. A successful Season rebuild occurs only if the player still belongs to Players and DataService exposes an active profile. A timed-out transaction caller requests close and kicks, while the worker retains ownership until completion. A later confirmed turn is finalized safely without rebuilding gameplay for the departing player. Preflight refusal due to another operation is RETRYABLE_FAILURE; the unchanged preview can be retried. Invalid candidates are rejected before starting a write.

# BR-003 Implementation

`WorkshopService:Respec` computes the future node set and both capacities **before** refunding currency/points or removing nodes. `Shared/GardenRules` supplies exactly the existing capacity formulas to StatsService, schema checks and respec, avoiding a second formula. Any nonempty slot beyond future garden capacity rejects the request with `RESPEC_GARDEN_OCCUPIED`. All balances, nodes and slots remain unchanged on rejection. Overflow bee equipment is removed from equipment only; BeeInventory is never reduced.

`GardenPlotService:RefreshCapacity` also checks overflow rather than shrinking over occupied content. A related destructive path, Plant replacing/unplanting a progressed slot, now rejects with `GARDEN_PROGRESS_PROTECTED` if level >1, XP/pollination >0, mutation or unknown extra slot metadata would be erased. Fresh unprogressed slot replacement retains existing behavior; planting the same species is a no-op. This is a conservative restriction, not a new per-copy storage system. Season's explicitly confirmed reset remains intentional.

# BR-009 Implementation

`Data/ProfileDomain.luau` adds domain checks to `ProfileSchema.Prepare` after the existing legacy migration. Preparation operates on a copy and returns `(false, reason)` without mutating the input on rejection. DefaultProfile, SchemaVersion=5, BloomReworkV1 identity and fruit-to-flower compensation rules remain unchanged. Future schema versions are refused rather than downgraded.

Unknown active registry entries move to `LegacyArchive.DomainV1`; unknown top-level historical fields and existing archive contents remain. Type replacements and repaired numeric values retain their original diagnostic values there. Dynamic Workshop source ids are not enumerated away: string-keyed boolean claims remain, preserving one-time reward provenance. Historical legacy fields removed from active state are now archived before removal.

Occupied invalid/unknown/unowned/overflow garden slots are rejected rather than silently erased or granted new ownership. This may prevent a malformed historical profile from loading, but preserves the stored record for deliberate repair. Excess bee equipment is safely normalized to current capacity and owned copy count, with displaced entries archived; counts remain owned. Unknown mutation strings and extra slot fields survive valid round trips.

# Persistence State Machine

| State / condition | Access and transition |
|---|---|
| Loading | One acquisition operation; no gameplay. Confirmed load → Active, or final release if leave/shutdown was requested. |
| Active | GetProfile enabled; one Save, Transaction or Release may start. |
| Saving | Ordinary autosave owns the writer; live gameplay is allowed until retry/failure or CloseRequested. |
| Transaction | GetProfile blocked; candidate isolated from live pre-turn data. |
| Closing / CloseRequested | Gameplay blocked. Existing operation finishes first, then final snapshot is written. |
| RetryPending | Same operation id/candidate; GetProfile blocked; bounded retries. |
| Released | Confirmed final write; record removed. |
| Lost | Token/lease ownership lost; no further write. Record retained for diagnostics. |
| UnknownOutcome | Attempt may have committed; no stale write/restart. Live and candidate retained. |
| RecoveryFailed | Definite refusal, invalid profile or exhausted no-write retries; record retained, no gameplay. |

GetPersistenceStatus exposes state/operation/result metadata only. It does not expose a mutable record or profile. A user rejoining this same server while a retained record exists is rejected; a different server still honors the durable lease until expiry. There is no infinite renewal or automatic overwrite of retained unknown records.

# Failure Outcome Semantics

Every persistence API returns a table: `Code`, `Committed`, `Pending`, `OperationId`, `Attempts`. `Committed=true` means confirmed success; false means **not confirmed**, not proof of no write.

| Code | Meaning |
|---|---|
| SUCCESS | Write or same-operation marker confirmed through UpdateAsync. |
| RETRYABLE_FAILURE | Operation not admitted, or explicit no-result/no-confirmation refusal without a caught uncertain error; retries bounded. |
| OWNERSHIP_LOST | Token absent/different/expired; old server stops writing. This does not claim whether an earlier uncertain attempt committed. |
| UNKNOWN_OUTCOME | Error may have occurred after commit; exact candidate retained; no stale fallback. |
| INVALID_PROFILE | Preflight/schema/envelope invalid; rejected. |
| TIMEOUT | Caller/global budget ended. With Pending=true the single worker remains in flight and must not be replaced. |
| NO_PROFILE | No matching local record; not a claim that a save occurred. |

Diagnostics identify operation, user id, state, attempt and result category. Healthy autosaves do not print repeated success logs. Failures, exhausted recovery and shutdown leftovers are logged without profile contents.

# Shutdown Behavior

DataConfig: six attempts per operation, exponential delays 1/2/4/8/8 seconds; caller observation budget 20 seconds; global shutdown wait budget 25 seconds. Per-player operations remain serialized while different users' releases run concurrently. Shutdown sets every close request before waiting. A slow user's UpdateAsync does not block launching other users' releases. Retry workers do not start new attempts after the shutdown deadline.

An already yielding engine DataStore call is not forcibly cancelled and no second writer is started after caller timeout. If it completes while the server still runs, its result is handled by the same owner. At the global deadline unresolved/in-flight records are logged. No additional Roblox shutdown time or guaranteed durability is assumed.

# Respec Safety Rules

1. Compute future garden and bee capacities from the node set after removal.
2. Reject any nonempty overflow garden slot before mutation/refund.
3. Refund/remove nodes only after validation.
4. Unequip overflow bees without changing owned counts.
5. Refresh capacity/synergies and tutorial from the valid resulting state.

The same server rules apply to direct remote calls; client state cannot bypass them. `UIStateService` supplies readable English rejection messages; no GUI model changes were needed.

# Schema Invariants

- NaN, infinity, unsupported values, cycles and invalid numeric keys reject preparation.
- Active currencies, counts, points, mastery XP, hive honey and progression counters are nonnegative; integral domains are floored and original repairs archived.
- The numeric safety ceiling is the exact IEEE-754 integer bound, 2^53−1. Beyond it preparation rejects instead of silently capping. Valid 2e12 currency is preserved. Configured hive/mastery/Bloom maxima continue to apply.
- Flower/bee/node/rarity/location/trial/card IDs are checked against registries. Unknown historical active entries are archived, not converted into free rewards.
- False owned Workshop node entries are removed so iteration cannot refund unowned nodes. Permanent owned nodes are marked in the existing LegacyNodes representation.
- Garden slots are indexed consistently, within effective capacity, use known flower IDs and do not exceed ownership. Conflicting aliases or meaningful invalid slots reject without changing source data.
- Equipment uses only owned bees within effective bee capacity; excess equipment does not delete bees.
- Favorites/protection/discoveries/settings use their intended types. Current Settings defaults and feature unlock rules remain.
- Migration fixtures retain old mapping, dust compensation, planted ownership repair, existing archives and idempotence. Successful prepare/mutate/validate/prepare preserves valid progress and unknown slot metadata.

# Tests Actually Executed

Command: `python3 tools/checks/phase2a_check.py`.

**53 assertions passed:** the existing 19 pure assertions, plus 34 Phase 2A cases. The current production DataService source is executed with a cooperative virtual-time scheduler and fault-injected UpdateAsync. Cases cover normal/failing/repeated final saves; definite no-write refusal; token and expired lease loss; lost final/transaction acknowledgements; unknown committed transaction protected from stale save; leave during autosave/Season; shutdown during a transaction and concurrent releases; hung operations bounded at shutdown; same-server rejoin; actual Season caller success/timeout paths; actual Start PlayerRemoving/BindToClose wiring; invalid live profile retention; respec and schema cases required by this task.

Results: `tests/phase2a_results.txt`. Runner: `tools/checks/phase2a_check.py`. New assertions: `tests/phase2a.lua`.

The original `python3 tools/checks/lua_check.py` was also attempted and failed on Luau `-=` in current InventoryService, before tests. Its historical success artifact was not reused as validation. The new runner reuses existing harness mocks, lowers simple compound assignments for Lua 5.4 and strips the existing DataConfig return annotation. Existing Bees helper substitutions are explicitly documented. This validates service logic, not Roblox's engine or network behavior.

Roblox Studio: **NOT AVAILABLE**. Real DataStore/API-failure tests and native Luau typechecking: **NOT RUN**.

# Static Checks

- Eleven changed Luau modules compiled via the documented Lua 5.4 compatibility check; not represented as a native Luau typecheck.
- `python3 -m py_compile tools/checks/phase2a_check.py` succeeded.
- Re-read changed persistence/schema/caller/capacity files after edits.
- Searched SaveProfile, ReleaseProfile, CommitProfile, Busy, capacity and recordsByUserId removal paths. One removal remains, guarded by confirmed Release success. Season is the sole external CommitProfile caller and checks result.Code. No PlayerService.Busy references remain.
- SaveProfile(true) delegates to ReleaseProfile; autosave ignores the result safely because the lifecycle owner handles every failure; PlayerRemoving and shutdown use the same per-record operation.
- Production store `FruitRNG_PlayerProfiles_v1`, Studio store `FruitRNG_PlayerProfiles_TEST_v1`, key prefix `Player_`, schema 5 and BloomReworkV1 unchanged.
- No client authority introduced. No GUI model, price, reward, rarity or drop-rate modifications.

# Remaining Risks

- Memory retention cannot survive process termination. A prolonged DataStore outage or hard server loss can still lose progress that was never durably confirmed. This implementation prevents silent successful-release treatment and stale overwrites; it does not promise impossible storage availability.
- Terminal unresolved records intentionally remain until server termination; repeated same-server joins are blocked, and cross-server joins must wait for durable lease expiry. Recovery requires diagnosis, not blindly saving the retained pre-turn table.
- An old inconsistent occupied garden profile now fails safe rather than losing slots. Such profiles require deliberate repair preserving the original data; no mass migration/wipe was attempted.
- Progressed/mutated flowers cannot currently be replaced/unplanted and a respec affecting them is blocked. A future explicit preservation/relocation flow would need separately designed storage; it is outside this task.
- Roblox Studio must still verify actual DataStore callback timing, throttling, serialization, real shutdown termination, and server/client state after these outcomes. The deterministic harness models these boundaries but does not prove platform integration.

# Deferred Phase 2 Issues

BR-002 inventory ownership, BR-005 snapshots, BR-006 public replication, BR-007 Workshop GUI lifecycle, BR-008 roulette correlation, BR-010 map/trial UX and BR-011–013 remain untouched. Phase 2B should verify current main again before work. Do not restore SeedSatchel merely from the Phase 1 label: recent history explicitly contains intentional Inventory V2 integration and old-template removal; that product decision needs to be respected when evaluating ownership.
