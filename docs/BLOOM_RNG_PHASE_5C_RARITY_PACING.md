# Bloom RNG Phase 5C — Rarity & Duplicate Pacing

## Root cause fixed

Discovery pity previously filtered the roulette to **every undiscovered result** once the pity threshold was reached.

That meant that after Common / Uncommon discoveries were exhausted, pity could eventually force Legendary, Mythic and even Celestial rewards regardless of their natural weights. The natural multi-hour rarity curve could therefore collapse into a few hundred rolls.

## New pity boundary

`BloomConfig.DiscoveryPityMaxRarity = "Epic"` is now the source of truth.

At the pity threshold:

- undiscovered Common / Uncommon / Rare / Epic entries can be used for the protected discovery result;
- Legendary / Mythic / Celestial entries are never forced by discovery pity;
- if there is no undiscovered result inside the protected tiers, the roulette keeps the normal weighted pool instead of forcing an endgame rarity.

The pity counter remains bounded at the configured threshold. This also means that when a player unlocks Crystal Greenhouse and new protected-tier flowers become eligible, the ready pity can immediately help the player catch up.

## Why Epic

The protected tiers are enough to satisfy progression requirements without consuming the endgame rarity chase.

Through Crystal Greenhouse the release set contains 8 flowers at Epic-or-below, matching the Season requirement of 8 discovered flowers.

The release bee set contains 6 bees at Epic-or-below, above the Season requirement of 5 discovered bees.

Legendary / Mythic / Celestial therefore remain aspirational RNG rewards rather than mandatory Season blockers.

## Natural early roulette

At current release weights, before luck/special-roll modifiers:

- Common: ~61.8%
- Uncommon: ~35.1%
- Rare: ~2.25%
- Epic: ~0.63%
- Legendary: ~0.11%
- Mythic: ~0.030%
- Celestial: ~0.0011%

That places Mythic around 1 / 3.3K and Celestial around 1 / 89K in the early natural pool.

## Player-facing copy

The Discovery Lens HUD no longer says `NEW GUARANTEED` when pity is full. It displays `PITY READY`, which remains truthful even when only endgame rarities are undiscovered.

## Duplicate pacing

Flower duplicates remain a progression resource through Petal Dust / Mastery, while planted and final copies are protected from dissolve.

Bee duplicate sinks are handled separately by the release sink pass; this phase only prevents pity from destroying their rarity curve.

## Verification

`tools/checks/rarity_duplicate_pacing_check.py` guards:

- the Epic pity cap;
- natural early rarity bands;
- Mythic / Celestial odds ranges;
- enough protected-tier content for Season progression;
- bounded pity timing;
- duplicate flower protections;
- truthful HUD copy.
