# Bloom RNG Phase 5B — Progression Pacing Guardrails

## Decision

No additional pacing nerf/buff was applied. After the Hive/location and Workshop-tree fixes, the release progression already has a usable early → mid → late ladder.

This phase locks the intended anchors so future balance edits do not accidentally turn the alpha into either a five-minute completion or a dead grind.

## Baseline anchors

All times below use base one-bee delivery values and therefore act as conservative upper-bound anchors before traits, abilities, activities and multi-bee scaling.

- Hive 2: ~1.33 minutes.
- Hive 4 / Crystal progression: ~12 minutes.
- Hive 6 / Twilight progression: ~55 minutes.
- Hive 8 / Season gate: ~189 one-bee minutes.
- Developed five-bee throughput equivalent for the same Hive requirement: ~38 minutes.

Real play naturally sits between the one-bee upper anchor and the developed multi-bee throughput floor because extra bees, traits, abilities and active tokens arrive gradually.

## Milestone ordering

- Sunny Orchard: Hive 2.
- Crystal Greenhouse: Hive 4 and Sunny unlocked.
- Workshop branches reach their deepest release tier by Hive 5.
- Twilight Grove: Hive 6 and Crystal unlocked.
- Season Turn: Hive 8 plus all sectors, 8 flowers, 5 bees and 3 key trials.

This prevents the major progression systems from all unlocking at the same Hive level.

## Long-form layers

Bee Mastery remains a long-running side progression at roughly 88 base delivery-minutes to cap before XP multipliers.

The permanent Legacy branch requires 21 Ancient Nectar against 5 base Nectar per Season, which keeps full Legacy progression in the multi-Season range.

## RNG cadence

The default 30-roll discovery pity at a 1.55-second roll cooldown yields a ~46.5-second ceiling before pity forces an eligible undiscovered result. This preserves RNG anticipation without allowing a basic collection step to stall indefinitely.

## CI

`tools/checks/progression_pacing_check.py` guards the early/mid/late Hive anchors, world milestone order, Workshop depth, Season breadth, Bee Mastery length, Legacy horizon and pity cadence.
