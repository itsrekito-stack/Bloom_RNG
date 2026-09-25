# Bloom RNG Phase 5F — Release Workshop Freeze

## Shipping tree

The v1 Workshop release set is frozen to seven branches:

- Roll
- Garden
- Bees
- Economy
- Bloom
- Exploration
- Legacy

Each branch ships exactly six nodes, for 42 non-core release nodes.

## Contract

`ReleaseContentManifest.luau` now records the ordered Workshop branch list and `WorkshopNodesPerBranch=6`.

The release content lock derives the exact expected node IDs from that contract:

`ROLL_1..6`, `GARDEN_1..6`, `BEES_1..6`, `ECONOMY_1..6`, `BLOOM_1..6`, `EXPLORATION_1..6`, and `LEGACY_1..6`.

It then requires the same exact set in `WorkshopEffectsConfig`.

This means a missing effect, accidental seventh node, new branch, removed branch, or branch-order drift becomes an explicit release-contract failure instead of silently changing v1 content.
