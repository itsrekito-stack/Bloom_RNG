# Bloom RNG Phase 5A — Economy Balance Guardrails

## Decision

No broad coefficient rebalance was applied in this phase. The current release economy already has healthy baseline relationships, so changing values only to create movement would add unnecessary risk.

Instead, deterministic guardrails now lock the intended source/sink relationships and pacing ranges.

## Baseline model

Using server-authoritative base values, before traits, abilities and active-world acceleration:

- Hive 1 → 2 requires 40 Honey = 10 base deliveries = about 80 seconds with one bee.
- Hive 1 → 8 requires 5660 cumulative Honey = about 188.7 one-bee minutes as an upper-bound baseline.
- With a developed multi-bee setup the same Honey requirement naturally compresses substantially.
- Those baseline deliveries produce about 8490 Coins by Hive 8.
- The six non-Legacy Workshop branches require about 3780 Coins in total at current node costs.
- First Workshop node costs 30 Coins while the Hive 2 baseline path produces 60 Coins.
- A first Flower Mastery purchase requires 5 Petal Dust; a duplicate is worth 3 Dust, so the first purchase needs roughly two duplicates.
- The full Legacy Nectar ladder costs 21 Ancient Nectar; at 5 base Nectar per Season this spans about five Seasons without acceleration.
- Delivery-only Bloom charge takes about 6.7 minutes with one bee before activities/multiple bees accelerate it.
- Base pity ceiling is about 46.5 seconds at the default roll cooldown.
- Minimum progression required for a first Season yields about 26 Workshop Points, enough for meaningful choices but not an automatic full 36-node seasonal tree.

## Currency source/sink map

Honey:
- source: pollinator deliveries;
- sink: Hive upgrades;
- reset: current Honey resets on Season Turn while TotalHoney persists.

Coins:
- source: pollinator deliveries, Journey, repeat trials and activity effects;
- sink: Workshop purchases;
- hard seasonal sink: Coin balance resets on Season Turn.

Petal Dust:
- source: duplicate flower dissolve, landmarks and shared-world rewards;
- sink: Flower Mastery and Economy/Bloom Workshop nodes.

Ancient Nectar:
- source: Season Turn and Season Scholar;
- sink: permanent Legacy Workshop nodes.

Workshop Points:
- source: Hive milestones, first trial completions and collection milestones;
- sink: Workshop node purchases;
- non-permanent points recycle through respec/Season reset, while permanent Legacy investment remains consumed.

## CI

`tools/checks/economy_balance_check.py` fails if source/sink wiring disappears or if key release pacing moves outside bounded guardrails.

This intentionally protects relationships rather than exact final-balance perfection; live telemetry can tune values after private alpha without silently creating a dead currency or a one-session Legacy completion.
