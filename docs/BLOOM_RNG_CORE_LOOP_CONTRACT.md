# Bloom RNG — Automated Core Loop Contract

This gate protects the source-level gameplay chain:

**Roll → Inventory → Garden → Bees / Pollination → Hive → Workshop**

It runs in `.github/workflows/gameplay-checks.yml` through:

`python tools/checks/core_loop_contract_check.py`

## What it verifies

The check asserts that current production modules retain the server-authoritative links required by the loop:

- RollService grants rewards through InventoryService and emits the authoritative Reward.
- Flower rewards become owned seed copies.
- SeedSatchel explicitly renders Inventory V2.
- Inventory planting hands off to the physical garden flow rather than bypassing proximity.
- GardenPlotService validates proximity and owned/free copies.
- Pollinator deliveries produce Honey/Coins, flower progression, Bee Mastery and Bloom charge.
- Hive grants/equips the starter bee and later converts Hive progress into Workshop points.
- Workshop purchases own a node and emit progression events.
- PlayerService still routes Roll, Plant and WorkshopBuy to the owning services.
- UIStateService still exposes Inventory and Workshop projections from server state.

## Limitation

This is **not** a Roblox Studio playtest.

It cannot prove actual input focus, tween timing, engine networking, real ProximityPrompt behavior, rendered clipping or DataStore timing. Those remain Studio-only acceptance items.

The purpose of this check is to catch structural regressions automatically before a human runtime test.
