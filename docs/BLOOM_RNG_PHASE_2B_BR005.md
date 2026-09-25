# Bloom RNG Phase 2B — BR-005 State Synchronization

## Scope

This change addresses BR-005 only. It does not redesign menus, rebalance progression, change reward authority, or implement BR-006/BR-007/BR-008.

## Changes

- Player state now has a separate UI state revision.
- Periodic one-second state sync remains as a coalescing boundary, but a full Snapshot is sent only when the player's state revision changed.
- Failed and no-op Remote requests no longer trigger a full Snapshot/Render cycle.
- Successful state-mutating actions mark state dirty centrally.
- Existing gameplay Emit events also mark state dirty, covering deliveries, rolls, tutorial events, abilities and most progression.
- Passive Journey/collection progression now reports whether it mutated state.
- Sector changes mark state dirty so Map UI remains current.
- Server Bloom rewards explicitly dirty every rewarded participant.
- Social pulse start/end marks connected players dirty.
- Active trials retain one-second state updates so TimeLeft remains live.
- StateRequest accepts an optional known revision and can answer NOT_MODIFIED without rebuilding a snapshot.
- Client ApplyState ignores duplicate revisions.

## Safety

Initial authoritative state is still forced after profile load/client-ready.

State snapshots remain server-authored. No client authority was added.

The existing SeasonService transaction revision remains separate from UI state revision.

## Expected effect

The previous path rebuilt the full profile copy, odds, Inventory/Workshop/Map/Trials UI projection and client RenderMenu every SyncSeconds=1 even with no relevant change, and also after every accepted request.

The new path coalesces these updates around real state changes. Exact CPU/network reductions require Roblox Studio profiling and are not claimed here.

## Remaining

BR-007 still needs the Workshop shell to remain mounted and patch node state in place. BR-006 public bee/activity replication remains separate.
