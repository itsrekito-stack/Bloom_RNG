# Bloom RNG Phase 4F — Bee Traits, Abilities & Equipment

## Problem

The release bee configuration described substantially more gameplay than the server executed. Several fields were presentation-only in practice: work power, Hive Honey, coin/critical traits, Mirror duration/clone scaling, Meadow splash/dual pollination, extra-target abilities, Crystal/Magma periodic ticks and Storm burst work.

There was also no Player XP system, while several bee configs claimed a Player XP multiplier.

## Runtime authority

`StatsService` now exposes the complete server-derived equipped-bee stat set used by pollination:

- luck, yield and travel speed;
- pollinator power and flower growth;
- coin and Hive Honey multipliers;
- ability cooldown and duration;
- clone power;
- Bee Mastery XP;
- critical chance/multiplier;
- splash and dual-pollination chance/power.

`PollinatorService` is the execution owner for configured bee mechanics.

## Ability execution

- `WorkMultiplier` changes real flower work while the ability is active.
- `RewardMultiplier` changes real delivery rewards.
- `HiveHoneyMultiplier` affects Hive Honey.
- `CriticalChanceBonus` participates in server-side critical rolls.
- Mirror clone power scales clone-style work and extra-target effects.
- Ability duration bonuses extend the actual active window.
- Bloom Queen / Shadow extra targets copy work to additional flowers.
- Crystal / Magma ticks are scheduled inside the existing server tick state; no per-bee delayed task loop was introduced.
- Storm burst immediately applies configured multi-target work/reward units.
- Ability-token chance now uses `BloomConfig.AbilityTokenChance` instead of a repeated literal.

## Equipment correctness

Pollinator runtime state is pruned when a bee is unequipped, replaced or exceeds current capacity. This prevents a removed bee from remaining in public bee replication.

InventoryService remains authoritative for slot bounds, ownership and duplicate equipped-copy counts.

## Removed fake configuration

Disconnected `PlayerXPMultiplier` values were removed because Bloom RNG currently has no Player XP progression system. Player-facing ability descriptions no longer promise that nonexistent reward.

## Verification

`tools/checks/bee_runtime_check.py` guards the configured mechanics against becoming disconnected from server runtime again. Existing Bee Mastery, Garden and core-loop contracts were updated to follow the centralized runtime paths.
