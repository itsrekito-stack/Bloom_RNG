# Bloom RNG Phase 5D — Release Content Lock

## v1 shipping set

The release content set is now frozen by CI. Accidental additions or removals fail the gameplay gate instead of silently changing the release build.

### Flowers — 12

Daisy, Tulip, Sunflower, Clover, Crystal Rose, Frost Lily, Prism Bloom, Moon Orchid, Nightshade, Void Lotus, Star Bloom, Ember Dahlia.

### Bees — 13

Worker Bee, Sprinter Bee, Nectar Bee, Scholar Bee, Twin Bee, Royal Bee, Prism Bee, Twilight Bee, Bloom Queen Bee, Crystal Bee, Magma Bee, Shadow Bee, Storm Bee.

### Locations — 3

Sunny Orchard, Crystal Greenhouse, Twilight Grove.

### Build Trials — 8

Base Season trials:
- Meadow Circuit
- Swift Route
- Crystal Triangle

Advanced trials:
- No-Celestial Trial
- Signature Bloom
- Twilight Pulse
- Minimal Garden
- Mutation Study

### Workshop — 7 branches

Roll, Garden, Bees, Economy, Bloom, Exploration, Legacy.

### Active-world activities — 12

Pollen Spark, Nectar Bud, Dew Drop, Pollen Trail, Cross Pollination, Overcharge, Bloom Surge, Pollen Wind, Solar Bloom, Crystal Resonance, Shadow Bloom, Firefly Route.

### Season cards — 5

Spring Resonance, Summer Swarm, Autumn Fortune, Crystal Season, Twilight Season.

### Journey — 20 objectives

The current 20-step Journey from Starter Bee through Season Ready is part of the v1 lock.

## Policy

This does **not** prevent future content development.

It means any change to the shipping set is now explicit: update the relevant gameplay config and intentionally update the release-content contract in the same reviewed change.

Runtime configs remain the gameplay source of truth; the CI manifest is a release-policy guard and is not required by runtime code.

## Verification

`tools/checks/release_content_lock_check.py` verifies exact IDs and counts for all locked release sets and preserves the three base Season trials as the stable Season-critical subset.
