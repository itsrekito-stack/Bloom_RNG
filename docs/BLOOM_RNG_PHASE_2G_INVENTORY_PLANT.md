# Bloom RNG Phase 2G — Inventory V2 Plant Flow

## Problem confirmed

Inventory V2 previously chose the first free garden slot and sent `Plant` directly from the menu.

The server correctly requires the player to be within InteractionDistance of the target garden pad, so the menu-wide action could return `TOO_FAR`.

At the same time, the physical garden pad already emitted `PlantPicker(slot)`, but BloomUI had no dedicated `Plant` renderer. The intended world-first flow therefore existed only halfway.

## New flow

Inventory V2 no longer sends the Plant mutation.

For a flower/seed with a free copy and an available garden slot, the action is now:

**PLANT AT GARDEN**

Using it:

1. stores the selected flower as `LastSeed`;
2. closes Inventory V2;
3. tells the player to use an unlocked physical garden pad.

The garden pad remains server-authored and proximity-gated.

When its prompt emits `PlantPicker(slot)`, BloomUI now renders a real picker:

- only free flower copies are shown;
- the flower selected in Inventory V2 is sorted first and marked with a star;
- choosing a flower sends `Plant(slot, id)`;
- the server still performs slot, item ownership and distance validation.

## Result

The UI no longer advertises a remote action that is expected to fail away from the garden.

Planting remains an active world interaction instead of another HUD-only progression action.

## Unchanged

Favorite, Protect, Dissolve, Mastery, Bee Equip/Unequip and all server ownership checks are unchanged.

## Studio acceptance

- Select a flower in Inventory V2 and press PLANT AT GARDEN.
- Walk to an empty garden pad.
- Trigger its prompt.
- Confirm preferred flower appears first.
- Plant it.
- Confirm Inventory/Garden state refreshes and a far-away direct Plant path no longer exists.
