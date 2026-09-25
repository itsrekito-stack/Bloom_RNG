# Bloom RNG Phase 2K — BR-012 Workshop Effect Authority

## Problem

Workshop V5 effect values were duplicated between `WorkshopEffectsConfig.luau` and runtime services. Several services embedded their own numeric literals, so a future config edit could silently drift away from actual gameplay.

A full source sweep also found two purchased nodes with no runtime consumer:

- `ROLL_3` — Fast Reveal
- `GARDEN_3` — Quick Replant

`BEES_2` was also described as a +20% token chance even though current runtime behavior made eligible rare-bee ability tokens guaranteed while the node was owned.

## Authority model

- `WorkshopV5.Nodes` remains the authority for node ownership.
- `WorkshopEffectsConfig.luau` is the single source of truth for numeric V5 effect values and named feature semantics.
- `Shared/WorkshopEffects.luau` provides explicit `Value`, `Feature` and `Owned` lookups.
- `WorkshopConfig.Tree` is documented as legacy/default layout metadata only. Runtime Workshop geometry is authored in `StarterGui/BloomUI.model.json`.

## Runtime migration

The existing runtime values are preserved and now read from the effect config for:

- Roll cooldowns and Bloom reserve;
- Bloom mutation/new/signature weighting;
- flower and bee slot capacity;
- adjacency range and synergy mastery XP;
- bee mastery XP, trait cooldown and active ability yield;
- duplicate Dust and milestone Coin yield;
- Flower Mastery study discount;
- activity charge, route charge and Crystal duration;
- public activity interval modifier;
- Legacy bee mastery and Season Nectar.

No numeric tuning was intentionally changed.

## Previously decorative nodes

### ROLL_3 — Fast Reveal

Now applies the existing `RevealScale=.75` only to client roulette settle/reveal timings:

- settle steps;
- minimum visual spin window;
- result pop animation;
- result hold.

It does not change server roll cooldown, reward selection, odds or granted items.

### GARDEN_3 — Quick Replant

After the player physically activates a garden pad, the Plant flow automatically reuses `LastSeed` when that flower still has a free copy.

Server-side proximity, ownership, slot and progression-protection validation remain unchanged. If no valid previous seed exists, the normal Plant picker is shown.

## BEES_2 metadata correction

The effect metadata now names the behavior `GuaranteedAbilityToken` because that matches the pre-existing runtime condition. Gameplay probability was not changed by this refactor.

## Verification

`tools/checks/workshop_effects_check.py` verifies:

- all 42 non-core V5 nodes have effect entries;
- numeric consumers use the shared effect API;
- stale hardcoded Workshop literals do not return;
- Fast Reveal and Quick Replant have runtime handlers;
- the geometry authority is documented.

The check runs in the normal Bloom RNG Gameplay Checks workflow.
