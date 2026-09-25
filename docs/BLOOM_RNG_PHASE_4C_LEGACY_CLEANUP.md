# Bloom RNG Phase 4C — Dead Legacy Cleanup

## Removed

The repository-retained React / ReactRoblox package tree under `ReplicatedStorage/Packages` and the unused `Shared/ReactPackages.luau` wrapper were removed.

Current Bloom RNG client startup is the authored `BloomUI` controller path and no active repository code uses the old React UI stack.

## Intentionally retained

Not every old-looking name is dead code:

- `Workspace/FruitOrchardHub.model.json` is current map geometry despite the historical filename.
- `Data/LegacyBloomMapping.luau` is required for safe returning-profile migration.
- Server/client cleanup guards for stale Studio roulette/UI residue remain as compatibility protection.

There is no shipping Research source path in the current `src` tree.

## Guard

`tools/checks/legacy_cleanup_check.py` prevents the retired React path from silently returning while also ensuring the active map and migration compatibility files remain present.
