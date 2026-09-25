# Bloom RNG Phase 3A — Core Progression Reachability

## Scope

This pass validates the deterministic source-level path:

Starter bee → starter flower → pollination/delivery → Roll → inventory/planting → Hive → Workshop → sector unlocks → key trials → Season Turn.

It does not claim to replace Roblox Studio input/render/network acceptance.

## Blocker found: Swift Route timing

`SwiftRoute` requires one `PollenTrail` completion and additionally requires completion within 60 seconds of trial start.

The normal garden activity rotation contains seven activity kinds at an 18-second interval. Depending on the player's current rotation index, the next ordinary `PollenTrail` can arrive after the 60-second Swift Route window (and in the worst case after the 120-second trial duration).

That made the key Season trial nondeterministically impossible.

## Fix

Starting `SwiftRoute` now creates a priority, trial-specific `PollenTrail` from the shrine immediately.

Priority trial offers may exceed the ordinary `MaxVisible` activity cap, so an unrelated pair of existing activities cannot make the trial impossible.

The activity still uses normal server-side pickup proximity, sector unlock, step order and expiry validation.

If the route cannot be created, the trial is rolled back instead of leaving an impossible active trial.

## Cleanup

A duplicated, unreachable second `NectarBud` branch inside `GardenActivityService:Collect` was removed. It referenced variables that belong to `Offer` and could never execute because an earlier `NectarBud` branch already matched the same kind.

## Reachability invariants

Automated checks cover:

- the default profile starts with an owned and planted Daisy;
- Hive interaction grants and equips Worker Bee;
- the tutorial reaches Roll through Work, Pollen Spark and Delivery without requiring a prior Roll;
- Hive upgrades award Workshop points;
- sector Hive thresholds are below the Season Hive requirement;
- Crystal Greenhouse is available by Hive 4, where base flower capacity reaches slot 6 for CrystalTriangle;
- all three Season key trials have deterministic event sources;
- Swift Route has an immediate PollenTrail source;
- Season requirements do not exceed the shipped flower/bee content counts;
- Season Turn reseeds a flower, retains a bee and returns the player to a playable garden.

Studio acceptance remains separate.
