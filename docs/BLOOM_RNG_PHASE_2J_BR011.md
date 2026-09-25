# Bloom RNG Phase 2J — BR-011 FlowersConfig Duplication

## Problem

`FlowersConfig.luau` repeated the same DropWeight / AllowedBiomes / GrowthProfile / Tags / PollinationEffect / model/color/VFX initialization block three times:

1. inside `GetSpecies`;
2. inside `Exists`;
3. again at module initialization.

That meant simple reads mutated every flower record and future edits could easily update one copy but not the others.

## Change

- Flower base declarations remain unchanged.
- Drop weights are defined once in `DROP_WEIGHTS`.
- Pollination effect overrides are defined once in `POLLINATION_EFFECTS`.
- Derived fields are initialized once when the module is required.
- `GetSpecies` is now a pure lookup.
- `Exists` is now a pure existence check.

## Behavior preserved

All release flower IDs, display names, rarities, shapes, colors, base yields, allowed sectors, drop weights, biome mappings, growth profile values, tags, pollination effects, adjacency range, mutation pool, model aliases, color aliases and VFX colors are unchanged.

No rarity, reward or progression balance was modified.
