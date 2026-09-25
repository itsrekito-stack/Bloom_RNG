# Bloom RNG Phase 5J — Post-Legacy Ancient Nectar Sink

## Problem

Ancient Nectar already had a long-term purpose while the permanent Legacy Workshop branch was incomplete. The six Legacy nodes cost a total of 21 Ancient Nectar.

After all six nodes were owned, however, Ancient Nectar kept accumulating from future Season Turns with no repeatable destination.

## Post-Legacy distillation

After owning `LEGACY_1` through `LEGACY_6`, the player can distill:

`1 Ancient Nectar → 10 Petal Dust`

The action is unavailable before the complete Legacy tree, so Ancient Nectar cannot be diverted away from its primary permanent progression role.

No profile schema field was added. Availability is derived entirely from existing permanent Workshop ownership and current currency balances.

## Balance

With `LEGACY_6` owned, a normal Season Turn awards 7 Ancient Nectar: the base 5 plus the +2 Legacy bonus.

If all of that Nectar is distilled, it produces 70 Petal Dust per Season.

The repeatable non-Legacy Workshop Dust sink is 126 Petal Dust per Season, before any additional Flower Mastery spending. Distillation therefore supplements late-game Dust income without replacing the Dust economy.

## Authority and UI

The server validates:

- all six Legacy nodes are owned;
- at least one Ancient Nectar is available;
- the fixed exchange cost/reward from `BloomConfig`.

Inventory V2 exposes the action on the Ancient Nectar resource card. Before full Legacy it shows `COMPLETE LEGACY TO DISTILL`; afterward it shows the fixed Nectar → Dust exchange.

RemoteService treats the action as a no-argument command and keeps the existing global rate limit.

## Verification

The endgame sink, economy balance and Inventory V2 contracts now require the post-Legacy distillation path and its server/UI wiring.
