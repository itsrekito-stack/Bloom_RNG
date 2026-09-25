# Bloom RNG Phase 5D — Release Flowers & Bees Freeze

## Shipping set

Bloom RNG v1 now has an explicit release contract for its collectible flower and bee set.

Flowers: 12 shipping species.
Bees: 13 shipping pollinators.

The exact IDs and final metadata are recorded in `ReplicatedStorage/Config/ReleaseContentManifest.luau`.

## Rarity cleanup

The runtime no longer carries an intermediate `Exotic` bee rarity that is silently converted to `Mythic`.

Bloom Queen Bee, Crystal Bee and Magma Bee are now authored directly as `Mythic`, matching the actual runtime rarity system.

## Icons

Every shipping bee has a concrete uploaded icon asset.

Dedicated flower icon assets are still optional. `IconsConfig.GetFlowerIcon` now guarantees the existing System Flower icon as a fallback instead of returning an empty image when a dedicated flower asset is not yet present.

Legacy fruit artwork remains available only as compatibility/history data and is explicitly excluded from the shipping collectible manifest.

## Drift protection

The existing `release_content_lock_check.py` now reads the manifest and verifies:

- exact flower IDs and rarities;
- exact bee IDs, rarities, ability IDs and sort order;
- valid release rarities;
- concrete bee icon coverage;
- non-empty flower icon fallback;
- release counts and the wider location/trial/Workshop/activity/Season/Journey set.

Any unplanned content addition/removal or metadata drift now fails gameplay CI.
