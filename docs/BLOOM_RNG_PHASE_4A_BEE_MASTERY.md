# Bloom RNG Phase 4A — Bee Mastery

## Goal

Make Bee Mastery a real progression layer instead of a hidden accumulating number.

## Runtime changes

- Bee Mastery remains server-authoritative and stored in the existing `Pollinators.BeeMastery[beeId]` numeric field.
- Level/state is derived from total XP, so no DataStore schema migration is required.
- Mastery has 10 levels and a 660 XP base ladder.
- Rewards are intentionally bounded: at max level a bee has +12% work speed, +13% delivery yield and -10% ability cooldown.
- Mastery bonuses apply only while that bee is equipped and working.

## XP sources fixed

The existing Arcane trait already advertised faster Bee Mastery growth, and Scholar/Prism abilities already declared `BeeMasteryXPMultiplier`, but the runtime did not consume those multipliers.

The delivery path now applies:

1. Workshop Bee XP multiplier.
2. Equipped-trait Bee Mastery XP multiplier.
3. Active bee ability Bee Mastery XP multiplier.

## Player feedback

Inventory V2 now shows, for selected bees:

- Bee Mastery level and cap.
- Current level progress bar.
- XP toward the next level.
- The next mastery reward.
- Current cumulative mastery bonus in the bee description.

Crossing a mastery level sends a concise in-game level-up message.

## Verification

`tools/checks/bee_mastery_check.py` guards the mastery ladder, balance bounds, runtime bonus hooks, XP multiplier hooks, authoritative UI payload and Inventory V2 presentation.

Roblox Studio runtime/input acceptance remains separate.
