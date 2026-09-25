# Bloom RNG Phase 4E — Garden Progression & Synergies

## Root causes fixed

Two progression sources were bypassing the normal rules:

1. Ember Dahlia's `Pulse` path wrote slot XP directly, so threshold crossing did not use the normal level-up/carry-over/visual path.
2. Completed garden activities wrote raw `BeeMastery += 1`, bypassing the Bee Mastery cap, Arcane/Workshop XP multipliers and level-up feedback.

## Centralized progression

`GardenPlotService:AddFlowerXP` now owns planted-flower XP:

- level thresholds;
- XP carry-over across a level;
- max-level bounding;
- TotalPollination;
- collection Flower Mastery;
- model scale;
- level/progress billboard refresh.

Normal bee deliveries and Pulse both use this path.

`PollinatorService:AddMastery` now owns Bee Mastery XP grants. Deliveries and activity rewards use the same cap/multipliers/feedback rules.

## Config authority

Garden base capacity now uses `BloomConfig.StartingSlots`, and flower growth XP/max level are derived from `BloomConfig` rather than repeated literals.

## Existing authority retained

Plant/replace still validates server-side slot, distance, item id and free copy. Progressed flowers remain protected from replacement. Dissolve still cannot consume planted copies or the final owned copy. Synergy detection remains server-owned.
