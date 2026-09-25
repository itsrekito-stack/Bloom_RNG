# Bloom RNG Phase 5E — Release Locations, Activities & Trials Freeze

## Locations

The v1 release world is frozen to three progression sectors:

- Sunny Orchard — Hive 2, Solar Bloom activity.
- Crystal Greenhouse — Hive 4, requires Sunny Orchard, Crystal Resonance activity.
- Twilight Grove — Hive 6, requires Crystal Greenhouse, Firefly Route activity.

These progression roles are now part of the release manifest, not just an implicit config convention.

## Activities

The release activity set is frozen to 12 IDs:

Pollen Spark, Nectar Bud, Dew Drop, Pollen Trail, Cross Pollination, Overcharge, Bloom Surge, Pollen Wind, Solar Bloom, Crystal Resonance, Shadow Bloom and Firefly Route.

## Trials

The release trial split is frozen by role:

Base Season trials:
- Meadow Circuit
- Swift Route
- Crystal Triangle

Advanced Workshop trials:
- No-Celestial Trial
- Signature Bloom
- Twilight Pulse
- Minimal Garden
- Mutation Study

The release contract records each trial's sector, progression event and base/advanced role.

## Drift protection

`release_content_lock_check.py` now derives these expectations from `ReleaseContentManifest.luau` and fails if a location prerequisite, location activity, activity ID, trial sector/event or base/advanced role changes unintentionally.
