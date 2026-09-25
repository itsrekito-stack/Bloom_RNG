# Bloom RNG Phase 5G — Final v1 Content Manifest

## Single release-set contract

`ReleaseContentManifest.luau` is now the single explicit v1 content-set contract.

It records:

- release ID and manifest version;
- rarity order;
- 12 flowers and their rarities;
- 13 bees, rarities, ability IDs and sort order;
- flower icon fallback policy and exclusion of legacy Fruit content;
- 3 locations with Hive/prerequisite/activity roles;
- 12 world activity IDs;
- 3 base + 5 advanced trials with sector/event roles;
- 7 Workshop branches and six nodes per branch;
- 5 Season cards;
- 3 key Season trials;
- 20 Journey objective IDs.

Gameplay configs remain authoritative for runtime values. The manifest does not duplicate economy numbers, timers or effect magnitudes; it freezes the identity and role of the content that ships in v1.

## CI behavior

`release_content_lock_check.py` derives its expected release sets from the manifest and compares them with the actual runtime configs.

An unplanned addition, removal, rename, rarity change, bee ability-ID change, location role change, trial role change, Workshop node-set change, Season card reorder or Journey reorder now fails gameplay CI.

This completes the release-content freeze without turning the manifest into a second gameplay implementation.
