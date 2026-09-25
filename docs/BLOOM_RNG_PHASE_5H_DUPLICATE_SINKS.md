# Bloom RNG Phase 5H — Duplicate Flower & Bee Sinks

## Flowers

Flower duplicates keep their existing server-authoritative loop:

- planted copies are excluded from the free-copy count;
- protected/favorite flowers cannot be dissolved;
- the final owned copy cannot be removed;
- dissolved copies award Petal Dust;
- the duplicate also advances Flower Mastery.

## Bees

Bee duplicates now have an equivalent late-game sink.

InventoryService tracks free bee copies as total owned copies minus equipped copies. A free duplicate can be dismantled into Petal Dust, while:

- equipped copies cannot be consumed;
- the final owned copy cannot be consumed;
- invalid quantities/IDs remain rejected;
- the request is still rate-limited and schema-validated by RemoteService.

The base Bee duplicate value is `BloomConfig.BeeDustPerCopy`. Autumn Fortune and the existing ECONOMY_3 duplicate-yield Workshop effect apply to the reward, matching the flower duplicate economy.

## Inventory V2

Selected bees now expose their free-copy dismantle state. When a free duplicate exists, the existing Dissolve button becomes:

`DISMANTLE ×1 • +<dust> DUST`

The client only requests the action; ownership, equipped-copy accounting and final-copy protection remain server-owned.

## Verification

`tools/checks/endgame_sinks_check.py` guards both flower and bee duplicate sinks, their protection rules, currency destination and Inventory V2/server wiring.
