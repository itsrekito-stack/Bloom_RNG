# Bloom RNG Phase 4G — Hive & Location Progression

## Ordered world progression

Release locations now form an explicit progression chain:

1. Sunny Orchard — Hive 2
2. Crystal Greenhouse — Hive 4 + Sunny Orchard unlocked
3. Twilight Grove — Hive 6 + Crystal Greenhouse unlocked

The server validates prerequisite sector, Hive level and physical gate proximity before setting an unlock. Sector flags are monotonic during a Season; there is no ordinary downgrade action.

## Hive feedback

The personal Hive prompt now reflects authoritative state:

- before the starter bee: `Get Worker Bee`;
- while upgradeable: `Upgrade Hive • <cost> Honey`;
- at cap: `Hive MAX`.

The prompt object text also shows the current Hive level and is refreshed after starter-bee grant and every garden rebuild/Hive upgrade.

Insufficient-Honey interaction reports the target Hive level, required Honey and current Honey. Reaching a Hive milestone that makes the next sequential location available sends a concise gate-ready message.

## UI/server agreement

Map UI state exposes prerequisite readiness in addition to Hive readiness and gate proximity. `CanUnlock` now matches the full server condition instead of showing a later sector as actionable just because the Hive level is high enough.

## Verification

`tools/checks/hive_location_progression_check.py` guards the Hive cost ladder, ordered sectors, prompt feedback, proximity/prerequisite authority and Season requirement for the full location chain.
